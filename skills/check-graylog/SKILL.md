---
name: check-graylog
description: Query Graylog logs via its REST API using the URL and API token stored in `pass`. Use when the user wants to check, search, or tail Graylog logs, or investigate errors/requests in logs.
argument-hint: '[optional: search query, e.g. "kubernetes_namespace_name:<namespace> AND message:error"]'
allowed-tools: Bash
---

# Check Graylog

Credentials live in the `pass` store (GPG passphrase is cached in macOS Keychain, so reads are non-interactive):

- `pass graylog/url` — base URL (e.g. `https://graylog.example.com`)
- `pass graylog/api-token` — API token

**Never print the token.** Always consume it via command substitution so it stays out of the transcript. Don't run bare `pass graylog/api-token` or echo it.

## Step 1: Load credentials and check connectivity

```bash
GL_URL="$(pass graylog/url)"
GL_AUTH="$(pass graylog/api-token):token"
curl -sS -u "$GL_AUTH" -H 'Accept: application/json' "$GL_URL/api/system" | jq '{version, hostname, lifecycle}'
```

Shell state does not persist between Bash calls, so re-load `GL_URL` / `GL_AUTH` in every call.

- `pass` error "not in the password store" → tell the user the entry is missing; don't guess values.
- Connection timeout → Graylog is likely behind the VPN; ask the user to check it's connected.
- 401 → token expired or revoked; ask the user to create a new one and save it with `pass insert -f graylog/api-token`.

## Step 2: Search

Relative search (last N seconds). Use the user's query, or `$ARGUMENTS` if given; default to `*`:

```bash
GL_URL="$(pass graylog/url)"; GL_AUTH="$(pass graylog/api-token):token"
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
