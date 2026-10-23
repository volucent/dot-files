---
name: check-qa-staging-db
description: Connect to the qa-staging Postgres database through a local kubectl port-forward, using credentials from `pass`. Use when the user wants to check, query, or inspect the qa-staging DB.
argument-hint: [optional: SQL query or what to look for]
allowed-tools: Bash
---

# Check qa-staging DB

The DB is reached through a port-forward that the user runs themselves (VPN must be up):

```bash
kubectl -n fin-plat-qa-staging port-forward pod/psql-1 5432:5432
```

If the pod has moved, find it with `kubectl get pods -A | grep -i -E 'psql|postgres'`.

Credentials live in two `pass` entries (GPG passphrase is cached in macOS Keychain, so reads are non-interactive):

- `fp/qa-staging/psql/u` — username
- `fp/qa-staging/psql/p` — password

**Never print the password.** Consume it via command substitution only. Don't run bare `pass fp/qa-staging/psql/p` or echo it.

Without `PGUSER`, psql falls back to the macOS username (`pasha`), which has no Postgres role and just prompts for a password — always set both variables.

## Step 1: Check the connection

Every session is **read-only by default** (`default_transaction_read_only=on`), so an accidental write fails instead of changing shared QA data.

```bash
PGPASSWORD="$(pass fp/qa-staging/psql/p)" \
PGUSER="$(pass fp/qa-staging/psql/u)" \
PGOPTIONS='-c default_transaction_read_only=on -c statement_timeout=30s' \
psql -h 127.0.0.1 -p 5432 -d fin_plat -X -c 'select 1'
```

Don't probe with `pg_isready` or retry in a loop: each connection that closes can drop the port-forward, so probes make it flakier.

- `connection refused` right after a call that succeeded → the port-forward dropped when the previous connection closed and the user's reconnect loop is coming back (about a second). Retry that call once.
- `connection refused` / `server closed the connection unexpectedly` otherwise, or on the retry → the port-forward isn't running. Stop and ask the user to (re)start it, and suggest an auto-reconnecting loop:

  ```bash
  while true; do kubectl -n fin-plat-qa-staging port-forward pod/psql-1 5432:5432; echo "port-forward dropped, reconnecting..."; sleep 1; done
  ```

  Don't start the port-forward yourself unless the user asks; it's a long-running process tied to their VPN session.
- `password authentication failed` → the stored credentials are wrong or rotated; ask the user to update them with `pass edit fp/qa-staging/psql/p` (and `/u`).

## Step 2: Query

Shell state does not persist between Bash calls, so repeat the env vars in each call. Batch related queries into **one** psql call (a heredoc) instead of one call per query, to keep connections — and port-forward drops — to a minimum:

```bash
PGPASSWORD="$(pass fp/qa-staging/psql/p)" PGUSER="$(pass fp/qa-staging/psql/u)" \
PGOPTIONS='-c default_transaction_read_only=on -c statement_timeout=30s' \
psql -h 127.0.0.1 -p 5432 -d fin_plat -X <<'SQL'
select current_user, version();
select count(*) from users;
SQL
```

The app database is `fin_plat`. Table names come from `@@map` in `prisma/schema.prisma` and don't always match the model name (e.g. `PlaidLinkTokenLog` → `plaid_link_tokens_logs`); check there or with `\dt` before guessing.

## Step 3: Explore

```bash
# databases
... psql -h 127.0.0.1 -p 5432 -d postgres -X -c '\l'
# tables in a database
... psql -h 127.0.0.1 -p 5432 -d fin_plat -X -c '\dt *.*'
# describe a table
... psql -h 127.0.0.1 -p 5432 -d fin_plat -X -c '\d <schema>.<table>'
```

(`...` = the same three env vars as Step 1.)

Add `LIMIT` to exploratory `SELECT`s. Use `$ARGUMENTS` as the query or goal if provided.

## Writes

Only write if the user explicitly asks. Then show them the exact statement first, and run it with `PGOPTIONS='-c statement_timeout=30s'` (read-only removed) inside a transaction:

```bash
... psql ... -X -v ON_ERROR_STOP=1 -c 'BEGIN; <statement>; COMMIT;'
```
