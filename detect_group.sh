#!/usr/bin/env bash
#
# detect_group.sh — detect the negotiated TLS 1.3 key-exchange group
#
# Usage:
#   ./detect_group.sh <host_or_url> [port]
#
# Examples:
#   ./detect_group.sh example.com
#   ./detect_group.sh example.com 8443
#   ./detect_group.sh https://example.com:443/path

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <host_or_url> [port]"
  exit 1
fi

raw="$1"
port="${2:-443}"

# Strip scheme and path, trim whitespace → hostport
hostport="${raw#*://}"
hostport="${hostport%%/*}"
hostport="$(echo -n "$hostport" | xargs)"

# Split host and port if given
if [[ "$hostport" == *:* ]]; then
  host="${hostport%%:*}"
  port="${hostport##*:}"
else
  host="$hostport"
fi

# Candidate groups: PQC-hybrid first, then classical
groups=(
  X25519MLKEM768   # PQC hybrid (ML-KEM + X25519)
  X25519           # classical most-common curve
  secp256r1        # another classical curve
)

for grp in "${groups[@]}"; do
  if openssl s_client \
       -connect "${host}:${port}" \
       -servername "${host}" \
       -tls1_3 \
       -curves "${grp}" \
       -brief \
       </dev/null \
       >/dev/null 2>&1
  then
    echo "$grp"
    exit 0
  fi
done

# If we reach here, none of the TLS1.3 handshakes succeeded
echo "No TLS 1.3 support; server appears to support only older TLS versions."
exit 2
