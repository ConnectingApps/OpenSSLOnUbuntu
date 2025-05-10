#!/usr/bin/env bash
#
# tls-version.sh — detect TLS version for a given host
#
# Usage:
#   ./tls-version.sh <url> [port]

set -euo pipefail

# --- Parse arguments ---
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <url> [port]" >&2
  exit 1
fi

raw_url="$1"
fallback_port="${2:-443}"

# Strip scheme and path, then trim whitespace
hostport="${raw_url#*://}"
hostport="${hostport%%/*}"
hostport="$(echo -n "$hostport" | xargs)"  # remove any leading/trailing spaces

# Extract host and optional port
if [[ "$hostport" == *:* ]]; then
  host="${hostport%%:*}"
  port="${hostport##*:}"
else
  host="$hostport"
  port="$fallback_port"
fi

# --- Probe with OpenSSL and capture all output ---
output=$(openssl s_client \
  -connect "${host}:${port}" \
  -servername "${host}" \
  -brief \
  </dev/null 2>&1)

# --- Extract the protocol line ---
line=$(printf '%s\n' "$output" \
  | grep -iE 'protocol version:|^ *Protocol *:' \
  | head -n1 || true)

if [[ -z "$line" ]]; then
  echo "Error: could not determine TLS version for ${host}:${port}" >&2
  # Optionally uncomment the next line to debug:
  # echo "$output" >&2
  exit 2
fi

# Parse just the version token (e.g. “TLSv1.3”)
tls_version=$(printf '%s\n' "$line" \
  | awk -F': ' '{print $NF}' \
  | tr -d ',')

echo "$tls_version"
