#!/usr/bin/env bash
# Every reverse payload must emit cleanly and (where possible) pass syntax checks.
set -u
cd "$(dirname "$0")/.."

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

bash -c "
source scripts/shell-core.sh
source scripts/shell-payloads.sh
export PAYLOAD_DIR=\"$TMP\"
fails=0
for id in bash-tcp bash-udp python python-pty php php-pentest perl ruby lua node powershell golang groovy java awk nc nc-udp ncat socat socat-tls ncat-ssl cryptcat openssl-rs; do
  emit_reverse_payload \"\$id\" 10.0.0.1 4444 >/dev/null 2>&1 || { echo \"EMIT_FAIL \$id\"; fails=1; }
done
[ \$fails = 0 ] && echo \"PAYLOADS_EMIT_OK (23 payloads)\"
"

# bash-based payloads must be syntactically valid
for f in "$TMP"/*.run; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in
        python-pty.run) continue ;;  # python, checked below
    esac
    if head -1 "$f" | grep -q "bash"; then
        bash -n "$f" || { echo "BASH_SYNTAX_FAIL $f"; exit 1; }
    fi
done

python3 -m py_compile "$TMP/python-pty.run" && echo "PAYLOADS_SYNTAX_OK"
