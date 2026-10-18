---
name: check-qa-staging-db
description: Connect to the qa-staging Postgres database through a local kubectl port-forward, using credentials from `pass`. Use when the user wants to check, query, or inspect the qa-staging DB.
argument-hint: [optional: SQL query or what to look for]
allowed-tools: Bash
---

# Check qa-staging DB

The DB is reached through a port-forward that the user runs themselves (VPN must be up):

```bash
kubectl port-forward <psql-pod> 5432:5432
```

If you need the pod name, find it with `kubectl get pods -A | grep -i -E 'psql|postgres'`.

Credentials live in `pass` entry `qa-staging/psql` (GPG passphrase is cached in macOS Keychain, so reads are non-interactive):

- line 1: password
- line 2: `username: <user>`

**Never print the password.** Consume it via command substitution only. Don't run bare `pass qa-staging/psql` or echo it.

## Step 1: Check the port-forward is up

```bash
pg_isready -h localhost -p 5432
```

If it reports `no response`, stop and tell the user the port-forward isn't running. Ask them to (re)start it, and suggest an auto-reconnecting loop if it keeps dropping (VPN blips and idle timeouts kill port-forwards):

```bash
while true; do kubectl port-forward <psql-pod> 5432:5432; echo "reconnecting..."; sleep 1; done
```

Don't start the port-forward yourself unless the user asks; it's a long-running process tied to their VPN session.

## Step 2: Connect

Every session is **read-only by default** (`default_transaction_read_only=on`), so an accidental write fails instead of changing shared QA data.

```bash
PGPASSWORD="$(pass qa-staging/psql | head -1)" \
PGUSER="$(pass qa-staging/psql | sed -n 's/^username: *//p')" \
PGOPTIONS='-c default_transaction_read_only=on -c statement_timeout=30s' \
psql -h localhost -p 5432 -d postgres -X -c 'select current_user, version();'
```

Shell state does not persist between Bash calls, so repeat the env vars in each call. Use `-c '<sql>'` for one-off queries; psql is non-interactive here.

- `password authentication failed` → the stored credentials are wrong or rotated; ask the user to update them with `pass edit qa-staging/psql`.
- `connection refused` / `server closed the connection unexpectedly` → the port-forward dropped; go back to Step 1.

## Step 3: Explore

```bash
# databases
... psql -h localhost -p 5432 -d postgres -X -c '\l'
# tables in a database
... psql -h localhost -p 5432 -d <db> -X -c '\dt *.*'
# describe a table
... psql -h localhost -p 5432 -d <db> -X -c '\d <schema>.<table>'
```

(`...` = the same three env vars as Step 2.)

Add `LIMIT` to exploratory `SELECT`s. Use `$ARGUMENTS` as the query or goal if provided.

## Writes

Only write if the user explicitly asks. Then show them the exact statement first, and run it with `PGOPTIONS='-c statement_timeout=30s'` (read-only removed) inside a transaction:

```bash
... psql ... -X -v ON_ERROR_STOP=1 -c 'BEGIN; <statement>; COMMIT;'
```
