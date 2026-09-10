#!/usr/bin/env bash
# ============================================================================
#  PotenFYR Studios - Multi-Shell Universal Egg :: scripts/shell-init-debug.sh
#  Debug/diagnostics shells: ssh-debug, strace-shell, tcpdump-shell, socat-probe.
# ============================================================================
# shellcheck source=shell-core.sh
[ -n "${SHELL_CORE_LOADED:-}" ] || source "${SCRIPTS_DIR}/shell-core.sh"

dbg_register() { dbg_register_id="$1"; SHELL_DESC_EXTRA["${1}"]="${2}"; return 0; }

# ---------------------------------------------------------------- ssh debug
init_ssh_debug() {
    local port="${SHELL_BIND_PORT:-2222}"
    local dir="${SERVER_DIR}/.ssh-host"
    mkdir -p "${dir}" /run/sshd 2>/dev/null || true
    pkg_install openssh-server || true
    have sshd || { fail "sshd unavailable"; return 1; }
    ensure_os_users

    for kt in ed25519 rsa; do
        kf="${dir}/ssh_host_${kt}_key"
        [ -f "${kf}" ] || ssh-keygen -q -t "${kt}" -N '' -f "${kf}" >/dev/null 2>&1 || true
    done

    local cfg="${dir}/sshd_debug_config"
    {
        printf 'Port %s\nListenAddress 0.0.0.0\n' "${port}"
        printf 'HostKey %s/ssh_host_ed25519_key\nHostKey %s/ssh_host_rsa_key\n' "${dir}" "${dir}"
        printf 'PasswordAuthentication yes\nPermitRootLogin no\nUsePAM no\nLogLevel DEBUG3\n'
        printf 'Subsystem sftp internal-sftp\n'
    } > "${cfg}"

    # DEBUG3 to CONSOLE: every auth attempt is visible live - the whole point.
    log "Starting sshd -ddd DEBUG3 on port ${port} (auth trace goes to console)..."
    /usr/sbin/sshd -d -d -d -f "${cfg}" -E "${SERVER_DIR}/logs/sshd-debug.log" || {
        fail "debug sshd failed"
        return 1
    }
    ssh_ready_wait "${port}" && ok "Debug sshd ready on ${port} (watch logs/sshd-debug.log)"
    dbg_register "ssh-debug" "
CONNECT (with client-side trace too):
  ssh -vvv -p ${port} <user>@<host>
WATCH:
  tail -f logs/sshd-debug.log     # server-side: every offer, method, decision
KEY COMPONENTS:
  -d -d -d    foreground + debug level 3 (no daemonize, full verbosity)
  -vvv        client side equivalent; the pair shows BOTH sides of auth"
    return 0
}

# ---------------------------------------------------------------- strace shell
init_strace_shell() {
    local port="${SHELL_BIND_PORT:-0}"
    pkg_install strace socat || true
    have strace || { fail "strace unavailable"; return 1; }
    local out="${SERVER_DIR}/logs/strace-session"
    if [ "${port}" != "0" ]; then
        log "Starting strace login shell on port ${port} (trace -> ${out}.log)..."
        setsid socat "TCP-LISTEN:${port},reuseaddr,fork" \
            "EXEC:/usr/bin/strace -f -t -o ${out}.log /bin/bash -i,pty,stderr" \
            >> /dev/null 2>&1 < /dev/null &
        CHILD_PIDS["strace-shell"]=$!
        ssh_ready_wait "${port}" && ok "strace shell ready on ${port}"
    else
        ok "strace installed; wrap any command: strace -f -o trace.log <cmd>"
    fi
    dbg_register "strace-shell" "
CONNECT:
  nc <host> ${port:-<allocated-port>}     # each connection traced separately
READ THE TRACE:
  less ${out}.log         # open/read/write/execve with args + errno
KEY COMPONENTS:
  -f    follow forks/threads;  -t timestamps;  -o file trace destination"
    return 0
}

# ---------------------------------------------------------------- tcpdump shell
init_tcpdump_shell() {
    pkg_install tcpdump || true
    have tcpdump || { fail "tcpdump unavailable (CAP_NET_RAW needed)"; return 1; }
    local pcap="${SERVER_DIR}/logs/session.pcap"
    if is_root; then
        log "Starting continuous capture -> ${pcap}..."
        setsid tcpdump -i any -w "${pcap}" -U >> /dev/null 2>&1 < /dev/null &
        CHILD_PIDS["tcpdump-shell"]=$!
        ok "Capture running: tcpdump -r ${pcap} to review"
    else
        warn "tcpdump needs root/CAP_NET_RAW; capture not started"
    fi
    dbg_register "tcpdump-shell" "
USE:
  tcpdump -r logs/session.pcap -nn          # read the capture
  tcpdump -i any -nn port <PORT>            # live filter
KEY COMPONENTS:
  -i any    all interfaces;  -w file pcap output;  -U per-packet flush"
    return 0
}

# ---------------------------------------------------------------- socat probe
init_socat_probe() {
    local port="${SHELL_BIND_PORT:-9000}"
    local target="${SHELL_PROBE_TARGET:-127.0.0.1:80}"
    pkg_install socat || true
    log "Starting probe relay :${port} -> ${target} (hex dump to console log)..."
    setsid socat -v "TCP-LISTEN:${port},reuseaddr,fork" "TCP:${target}" \
        >> "${SERVER_DIR}/logs/socat-probe.log" 2>&1 < /dev/null &
    CHILD_PIDS["socat-probe"]=$!
    ssh_ready_wait "${port}" && ok "Probe relay ready on ${port}"
    dbg_register "socat-probe" "
CONNECT (through the relay):
  nc <host> ${port}          # bytes flow both ways, logged with -v
READ THE DUMP:
  tail -f logs/socat-probe.log    # '>' inbound to target, '<' outbound
KEY COMPONENTS:
  -v            hex+ascii dump of both directions
  TCP:${target}  set SHELL_PROBE_TARGET to re-point the far end"
    return 0
}
