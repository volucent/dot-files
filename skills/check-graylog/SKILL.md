---
name: check-graylog
description: Query Graylog logs via its REST API through a local kubectl port-forward, using the API token stored in `pass`. Use when the user wants to check, search, or tail Graylog logs, or investigate errors/requests in logs.
argument-hint: '[optional: search query, e.g. "kubernetes_namespace_name:<namespace> AND message:error"]'
allowed-tools: Bash
---

# Check Graylog

Graylog has no public URL. It is reached through a port-forward that the user runs themselves (VPN must be up):

```bash
kubectl -n graylog port-forward svc/graylog-web 9000:9000
```

The user has it aliased as `pf-gl`. The API is then at `http://127.0.0.1:9000`. If the service has moved, find it with `kubectl get svc -A | grep -i graylog`.

The API token lives in `pass graylog/api-token` (GPG passphrase is cached in macOS Keychain, so reads are non-interactive).

**Never print the token.** Always consume it via command substitution so it stays out of the transcript. Don't run bare `pass graylog/api-token` or echo it.

## Step 1: Check connectivity

```bash
GL_URL=http://127.0.0.1:9000
GL_AUTH="$(pass graylog/api-token):token"
curl -sS -m 15 -u "$GL_AUTH" -H 'Accept: application/json' -w '\nhttp=%{http_code}\n' "$GL_URL/api/system"
```

Shell state does not persist between Bash calls, so set `GL_URL` / `GL_AUTH` in every call. Keep the `-w 'http=%{http_code}'` (or otherwise check the status): a 401 has an empty body, so piping straight to `jq` prints nothing and looks like success.

- `connection refused` → the port-forward isn't running. Stop and ask the user to (re)start it, and suggest an auto-reconnecting loop:

  ```bash
  while true; do kubectl -n graylog port-forward svc/graylog-web 9000:9000; echo "port-forward dropped, reconnecting..."; sleep 1; done
  ```

  Don't start the port-forward yourself unless the user asks; it's a long-running process tied to their VPN session.
- `kubectl` hangs or times out → the VPN is down; ask the user to connect it.
- `pass` error "not in the password store" → tell the user the entry is missing; don't guess values.
- 401 → token expired or revoked; ask the user to create a new one in the UI at `http://127.0.0.1:9000` (profile → Edit tokens) and save it with `pass insert -f graylog/api-token`.

## Step 2: Search

Relative search (last N seconds). Use the user's query, or `$ARGUMENTS` if given; default to `*`:

```bash
GL_URL=http://127.0.0.1:9000; GL_AUTH="$(pass graylog/api-token):token"
curl -sS -u "$GL_AUTH" -H 'Accept: application/json' -G "$GL_URL/api/search/universal/relative" \
  --data-urlencode 'query=kubernetes_namespace_name:<namespace> AND message:error' \
  --data-urlencode 'range=3600' \
  --data-urlencode 'limit=50' \
  --data-urlencode 'sort=timestamp:desc' \
  --data-urlencode 'fields=timestamp,kubernetes_namespace_name,kubernetes_container_name,kubernetes_pod_name,message' \
  | jq '.total_results, (.messages[].message | {timestamp, ns: .kubernetes_namespace_name, container: .kubernetes_container_name, pod: .kubernetes_pod_name, message})'
```

- `range` is in seconds (300 = 5 min, 3600 = 1 h, 86400 = 1 day).
- For an absolute window, use `/api/search/universal/absolute` with `from` / `to` (ISO 8601, e.g. `2026-10-17T10:00:00.000Z`) in place of `range`.
- Logs come from Kubernetes. To find namespace names, count them over recent messages:
  `... --data-urlencode 'query=*' --data-urlencode 'range=3600' --data-urlencode 'limit=2000' --data-urlencode 'fields=kubernetes_namespace_name' | jq -r '[.messages[].message.kubernetes_namespace_name] | group_by(.) | map("\(.[0]) \(length)")[]'`
- Useful fields: `kubernetes_namespace_name`, `kubernetes_container_name`, `kubernetes_pod_name`, `kubernetes_labels_app`, `message`. There is no `level` field, so find errors with full-text terms like `message:error OR message:exception`.
- Query syntax is Lucene: `field:value`, `message:"exact phrase"`, `NOT`, `AND`, `OR`, wildcards `foo*`.
- To discover field names, run a broad search with `limit=5` and no `fields`, then inspect the keys.
- Leading wildcards (`*qa*`) are rejected; use exact values or trailing wildcards.
- To filter to one stream, list them with `curl ... "$GL_URL/api/streams" | jq '.streams[] | {id, title}'` and add `--data-urlencode 'filter=streams:<id>'`.

Any POST/PUT/DELETE request needs `-H 'X-Requested-By: cli'`. This skill is read-only, so don't change Graylog config (streams, inputs, alerts) unless the user explicitly asks.

## Step 3: Report

Summarize what you found: counts, the distinct error messages, first and last occurrence, and affected sources. Quote a few representative log lines rather than dumping everything.
