#!/usr/bin/env bash
#
# tls-cipher.sh — detect negotiated TLS cipher suite for a given host
#
# Usage:
#   ./tls-cipher.sh <url> [port]
#
# Examples:
#   ./tls-cipher.sh example.com
#   ./tls-cipher.sh https://example.com
#   ./tls-cipher.sh example.com 8443
#   ./tls-cipher.sh https://example.com:8443/path

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
hostport="$(echo -n "$hostport" | xargs)"  # trim

# Extract host and optional port
if [[ "$hostport" == *:* ]]; then
  host="${hostport%%:*}"
  port="${hostport##*:}"
else
  host="$hostport"
  port="$fallback_port"
fi

# --- Perform TLS handshake and capture output ---
output=$(openssl s_client \
  -connect "${host}:${port}" \
  -servername "${host}" \
  -brief \
  </dev/null 2>&1)

# --- Extract the cipher line ---
cipher_line=$(printf '%s\n' "$output" \
  | grep -i 'Ciphersuite:' \
  | head -n1 || true)

if [[ -z "$cipher_line" ]]; then
  cipher_line=$(printf '%s\n' "$output" \
    | grep -iE '^ *Cipher *:' \
    | head -n1 || true)
fi

if [[ -z "$cipher_line" ]]; then
  echo "Error: could not determine cipher suite for ${host}:${port}" >&2
  exit 2
fi

# --- Parse the cipher suite name ---
if [[ $cipher_line == *Ciphersuite:* ]]; then
  # TLS 1.3 output: “Protocol version: TLSv1.3, Ciphersuite: NAME”
  cipher=$(echo "$cipher_line" \
    | sed -E 's/.*Ciphersuite: *([^, ]+).*/\1/')
else
  # TLS 1.2 and below: “Cipher    : NAME”
  cipher=$(echo "$cipher_line" \
    | sed -E 's/.*Cipher *: *(.+)$/\1/')
fi

# --- Print result ---
echo "$cipher"
