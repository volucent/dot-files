#!/usr/bin/env bash
set -euo pipefail

KEY="DATABASE_URL"

mapfile -t env_files < <(find . -maxdepth 1 -type f \( -name '.env' -o -name '.env.*' \) | sort)

if [[ ${#env_files[@]} -eq 0 ]]; then
  echo "No .env files found in current directory." >&2
  exit 1
fi

echo "Choose an env file:"
PS3="> "
select env_file in "${env_files[@]}"; do
  if [[ -n "${env_file:-}" ]]; then
    break
  fi
  echo "Invalid selection. Try again." >&2
done

value="$({
  grep -E "^[[:space:]]*${KEY}[[:space:]]*=" "$env_file" | head -n 1 || true
} | sed -E "s/^[[:space:]]*${KEY}[[:space:]]*=[[:space:]]*//" | sed -E "s/^[\"'](.*)[\"']$/\1/")"

if [[ -z "$value" ]]; then
  echo "${KEY} not found in ${env_file}" >&2
  exit 2
fi

# printf '%s\n' "$value"
psql "$value"
