#!/usr/bin/env bash
# ============================================================================
#  PotenFYR Studios - Multi-Shell Universal Egg :: scripts/shell-init-reverse.sh
#  Reverse-shell handlers. Every handler:
#    1. ensures its interpreter/tool exists (best-effort pkg_install),
#    2. emits a reconnecting payload via emit_reverse_payload,
#    3. registers its start function on the supervisor.
#  Direction: the container connects OUT to <target-host>:<target-port>.
# ============================================================================
# shellcheck source=shell-core.sh
[ -n "${SHELL_CORE_LOADED:-}" ] || source "${SCRIPTS_DIR}/shell-core.sh"
# shellcheck source=shell-payloads.sh
[ -n "${SHELL_PAYLOADS_LOADED:-}" ] || source "${SCRIPTS_DIR}/shell-payloads.sh"
SHELL_PAYLOADS_LOADED=1

reverse_target() { # -> echoes "<host> <port>"
    printf '%s\n' "${SHELL_REVERSE_HOST:-} ${SHELL_REVERSE_PORT:-4444}"
}

reverse_register() { # reverse_register <id> <start_fn_name> <tool> <pkg>
    local id="$1" fn="$2" tool="$3" pkg="${4:-$3}"
    if ! have "${tool}"; then
        pkg_install "${pkg}" || true
    fi
    if ! have "${tool}"; then
        warn "${id}: '${tool}' unavailable in this image - payload still generated"
    fi
    shell_enable "${id}" "${fn}"
    return 0
}

# One generic runner: payloads already embed reconnect logic, so the
# supervisor just (re)starts the payload script.
_rev_common_start() { # _rev_common_start <id>
    local id="$1"
    local rhost rport
    read -r rhost rport <<< "$(reverse_target)"
    local path
    path=$(emit_reverse_payload "${id}" "${rhost}" "${rport}") || return 1
    REV_PAYLOAD_PATH["${id}"]="${path}"
    return 0
}

for _rev in bash-tcp bash-udp python python-pty php php-pentest perl ruby lua node powershell golang groovy java awk nc nc-udp ncat socat socat-tls ncat-ssl cryptcat openssl-rs; do
    eval "
rev_start_${_rev//-/_}() { _rev_common_start '${_rev}'; }
"
done
unset _rev

init_reverse_generic() { # init_reverse_generic <id>
    local id="$1"
    local fn="rev_start_${id//-/_}"
    local tool_map="bash-tcp:bash bash-udp:bash python:python3 python-pty:python3 php:php php-pentest:php perl:perl ruby:ruby lua:lua node:node powershell:pwsh golang:go groovy:groovy java:java awk:gawk nc:nc nc-udp:nc ncat:ncat socat:socat socat-tls:socat ncat-ssl:ncat cryptcat:cryptcat openssl-rs:openssl"
    local tool
    tool=$(printf '%s' "${tool_map}" | tr ' ' '\n' | grep "^${id}:" | cut -d: -f2)
    reverse_register "${id}" "${fn}" "${tool:-${id}}" "${tool:-${id}}"
    _rev_common_start "${id}" || return 1
    local rhost rport
    read -r rhost rport <<< "$(reverse_target)"
    SHELL_DESC_EXTRA["${id}"]="connects out to ${rhost}:${rport} (listener: nc -lvnp ${rport})"
    return 0
}
