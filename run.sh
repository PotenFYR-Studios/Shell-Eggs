#!/usr/bin/env bash
# ============================================================================
#  PotenFYR Studios - Multi-Shell Universal Egg :: run.sh
#  Dispatcher + supervisor. Sourced: shell-core, registry, family handlers.
#  Lifecycle: resolve selection -> plan users -> init handlers -> supervise.
#  Exit semantics: only an empty fd3/stdin trigger or SIGTERM/SIGINT exits 0.
# ============================================================================
set -u
umask 077

SHELL_EGGS_VERSION="${SHELL_EGGS_VERSION:-1.0.0}"
export SCRIPTS_DIR="${SCRIPTS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts}"
SERVER_DIR="${SERVER_DIR:-$PWD}"
cd "${SERVER_DIR}" || exit 1
mkdir -p "${SERVER_DIR}/logs" "${SERVER_DIR}/payloads" 2>/dev/null || true

# ---------------------------------------------------------------- core + registry
# shellcheck source=scripts/shell-core.sh
source "${SCRIPTS_DIR}/shell-core.sh"
# shellcheck source=scripts/shell-registry.sh
source "${SCRIPTS_DIR}/shell-registry.sh"
# shellcheck source=scripts/shell-init-server.sh
source "${SCRIPTS_DIR}/shell-init-server.sh"
# shellcheck source=scripts/shell-init-mux.sh
source "${SCRIPTS_DIR}/shell-init-mux.sh"
# shellcheck source=scripts/shell-init-reverse.sh
source "${SCRIPTS_DIR}/shell-init-reverse.sh"
# shellcheck source=scripts/shell-init-tunnel.sh
source "${SCRIPTS_DIR}/shell-init-tunnel.sh"
# shellcheck source=scripts/shell-init-bind.sh
source "${SCRIPTS_DIR}/shell-init-bind.sh"
# shellcheck source=scripts/shell-init-web.sh
[ -f "${SCRIPTS_DIR}/shell-init-web.sh" ] && source "${SCRIPTS_DIR}/shell-init-web.sh"
# shellcheck source=scripts/shell-init-debug.sh
[ -f "${SCRIPTS_DIR}/shell-init-debug.sh" ] && source "${SCRIPTS_DIR}/shell-init-debug.sh"
# shellcheck source=scripts/shell-payloads.sh
source "${SCRIPTS_DIR}/shell-payloads.sh"

declare -A REV_PAYLOAD_PATH
declare -A CHILD_PIDS          # id -> pid
PANEL_STOP_WORDS="stop exit shutdown reboot kill restart halt poweroff"
STOP_TRIGGERED=0

# ---------------------------------------------------------------- fd3 stop watcher
watch_panel_stop() { # watch_panel_stop <fd>
    local line
    while IFS= read -r line <&"$1"; do
        line="${line%$'\r'}"
        line="${line#"${line%%[![:space:]]*}"}"   # ltrim
        line="${line%"${line##*[![:space:]]}"}"   # rtrim
        [ -z "${line}" ] && continue
        case " ${PANEL_STOP_WORDS} " in
            *" ${line,,} "*)
                log "Panel stop trigger: ${line}"
                STOP_TRIGGERED=1
                kill -TERM "$$" 2>/dev/null
                return 0
                ;;
        esac
    done
}
WATCH_STOP_FD="${PANEL_STOP_FD:-3}"
case "${PANEL_STOP_WATCHER:-auto}" in
    0|false|off) : ;;
    *) eval "watch_panel_stop ${WATCH_STOP_FD} & WATCHER_PID=\$!" ;;
esac

# ---------------------------------------------------------------- shutdown
get_all_child_pids() { # descendants of $1
    local kids pids="" queue="$1" pid
    queue="$(ps -o pid= --ppid "$1" 2>/dev/null | tr -d ' ')"
    while [ -n "${queue}" ]; do
        pid="${queue%% *}"
        queue="${queue#* }"
        [ -n "${pid}" ] || continue
        pids="${pids} ${pid}"
        queue="${queue} $(ps -o pid= --ppid "${pid}" 2>/dev/null | tr -d ' ')"
    done
    printf '%s\n' "${pids}"
}

terminate_process_tree() { # terminate_process_tree <pid> <label>
    local pid="$1" label="${2:-pid $1}" kids
    kids=$(get_all_child_pids "${pid}")
    kill -TERM ${kids} "${pid}" 2>/dev/null || true
    sleep 1
    kill -KILL ${kids} "${pid}" 2>/dev/null || true
    log "Stopped ${label}"
}

sweep_known_daemons() {
    local p
    for p in sshd dropbear in.telnetd telnetd; do
        pkill -TERM -x "${p}" 2>/dev/null || true
    done
    sleep 1
    for p in sshd dropbear in.telnetd telnetd; do
        pkill -KILL -x "${p}" 2>/dev/null || true
    done
}

do_shutdown() {
    trap - TERM INT
    log "Shutting down Multi-Shell Egg (all services)..."
    local id pid
    for id in "${!CHILD_PIDS[@]}"; do
        pid="${CHILD_PIDS[${id}]}"
        kill -0 "${pid}" 2>/dev/null || continue
        terminate_process_tree "${pid}" "$(reg_field "${id}" 1)"
    done
    sweep_known_daemons
    ok "All shells stopped."
    if [ "${STOP_TRIGGERED}" = "1" ]; then
        exit 0
    fi
}
trap '_on_trap_signal TERM' TERM
trap '_on_trap_signal INT' INT
_on_trap_signal() {
    STOP_TRIGGERED=1
    do_shutdown
    exit 0
}

# ---------------------------------------------------------------- resolution
norm_shell_id() { # alias -> registry id
    case "$1" in
        openssh|sshd|ssh-server)        printf 'ssh' ;;
        telnet|telnet-server|telnetd)   printf 'telnetd' ;;
        mosh)                           printf 'mosh-server' ;;
        zellij|zj)                      printf 'zellij' ;;
        openssl|openssl-reverse)        printf 'openssl-rs' ;;
        nc6|netcat)                     printf 'nc' ;;
        *)                              printf '%s' "$1" ;;
    esac
}

resolve_selection() { # fills SHELL_ENABLED_IDS + SHELL_START_FN
    local wanted="${SHELL_TYPE:-auto}"
    local id first_port_set=0

    if [ "${wanted}" = "auto" ] || [ "${wanted}" = "interactive" ]; then
        # Marker from interactive picker; otherwise a friendly default.
        local marker="${SCRIPTS_DIR}/../.sh-autostart"
        if [ -f "${marker}" ]; then
            # shellcheck disable=SC1091
            source "${marker}"
        fi
        if [ -n "${SHELL_PICKED_TYPE:-}" ]; then
            wanted="${SHELL_PICKED_TYPE}"
        elif [ -n "${SHELL_TYPE:-}" ] && [ "${SHELL_TYPE}" != "auto" ] && [ "${SHELL_TYPE}" != "interactive" ]; then
            wanted="${SHELL_TYPE}"
        else
            wanted="ssh"
            warn "SHELL_TYPE=auto with no interactive choice; defaulting to OpenSSH on port ${SERVER_PORT:-22}. Set SHELL_TYPE explicitly or pick in console."
        fi
    fi

    local -a chosen=()
    local -a extras=()
    IFS=',' read -r -a chosen <<< "${wanted}"
    [ -n "${SHELL_EXTRA_TYPES:-}" ] && IFS=',' read -r -a extras <<< "${SHELL_EXTRA_TYPES}"

    local seen=""
    local -a extra_ports=()
    [ -n "${SHELL_EXTRA_PORTS:-}" ] && IFS=',' read -r -a extra_ports <<< "${SHELL_EXTRA_PORTS}"

    for id in "${chosen[@]}" "${extras[@]}"; do
        id="${id// /}"
        [ -n "${id}" ] || continue
        id=$(norm_shell_id "${id}")
        case " ${seen} " in *" ${id} "*) continue ;; esac
        if [ -z "${REGISTRY_META[${id}]:-}" ]; then
            warn "Unknown shell type '${id}' - skipping (see shell-registry.sh)"
            continue
        fi
        seen="${seen} ${id}"
        local port0 root_need
        port0=$(reg_field "${id}" 3)
        root_need=$(reg_field "${id}" 4)

        # Port policy (panels + docker):
        #   1st ported shell ALWAYS binds the panel-assigned SERVER_PORT.
        #   next ported shells consume SHELL_EXTRA_PORTS positionally, then
        #   auto-allocate above the primary port.
        local bind
        if [ "${port0}" != "0" ]; then
            if [ "${first_port_set}" = "0" ]; then
                bind="${SERVER_PORT:-${port0}}"
                first_port_set=1
            elif [ "${#extra_ports[@]}" -gt 0 ]; then
                bind="${extra_ports[0]}"
                extra_ports=("${extra_ports[@]:1}")
                [ -n "${bind}" ] || bind=$(( ${SERVER_PORT:-${port0}} + 10 ))
            else
                bind=$(( ${SERVER_PORT:-${port0}} + 10 ))
                warn "No SHELL_EXTRA_PORTS slot left for '${id}'; hoping ${bind} is allocated in the panel."
            fi
        else
            bind="0"   # multiplexers / reverse shells: no inbound port
        fi

        case "${id}" in
            ssh|ssh-cert|ssh-hardened|ssh-local|ssh-remote|ssh-dynamic|ssh-x11|rsync-ssh|sshfs|dropbear|telnetd|mosh-server|tmux|screen|zellij|nc-bind|socat-bind|openssl-bind|php-bind|python-bind|ttyd|gotty|php-webshell|node-webshell|ssh-debug|strace-shell|tcpdump-shell|socat-probe)
                shell_enable "${id}" "init_${id//-/_}"
                ;;
            *)
                shell_enable "${id}" "init_reverse_generic"
                ;;
        esac
        SHELL_ALLOCATED_PORTS["${id}"]="${bind}"
    done

    if [ "${#SHELL_ENABLED_IDS[@]}" = "0" ]; then
        fail "No valid shell selected; refusing to boot empty."
        exit 1
    fi
}

# ---------------------------------------------------------------- init
init_all_shells() {
    local id fn rc failures=0
    for id in "${SHELL_ENABLED_IDS[@]}"; do
        fn="${SHELL_START_FN[${id}]}"
        # Per-shell bind: the panel-assigned port (primary shell takes
        # SERVER_PORT) is exported as SHELL_BIND_PORT for the handler.
        local bind="${SHELL_ALLOCATED_PORTS[${id}]:-}"
        if [ -n "${bind}" ] && [ "${bind}" != "0" ]; then
            export SHELL_BIND_PORT="${bind}"
        fi
        log "Initializing $(reg_field "${id}" 1) [${id}]${bind:+ on port ${bind}}..."
        "${fn}" "${id}"
        rc=$?
        if [ "${rc}" != "0" ]; then
            fail "$(reg_field "${id}" 1) init failed (rc=${rc})"
            failures=$((failures + 1))
        fi
    done
    return "${failures}"
}

# ---------------------------------------------------------------- connection guide
print_connection_guide() {
    local id port
    printf '\n'
    log "Connection guide:"
    for id in "${SHELL_ENABLED_IDS[@]}"; do
        port="${SHELL_ALLOCATED_PORTS[${id}]:-}"
        printf '  \033[32m%-24s\033[0m %s\n' "$(reg_field "${id}" 1)" "${SHELL_DESC_EXTRA[${id}]:-see docs/}"
        if [ -n "${port}" ] && [ "${port}" != "0" ]; then
            printf '  \033[2m%-24s\033[0m \033[2mport: %s (allocate this port in the panel)\033[0m\n' '' "${port}"
        fi
    done
    if [ -n "${GENERATED_CREDENTIALS:-}" ] && [ "${SHELL_SHOW_CREDENTIALS:-1}" = "1" ]; then
        printf '  \033[33m%-24s\033[0m %s\n' "Users" "${GENERATED_CREDENTIALS}"
        printf '  \033[2m%-24s\033[0m \033[2m(also persisted in .env / .db-shells/credentials, mode 600)\033[0m\n' ''
    fi
}

# ---------------------------------------------------------------- persistence
persist_credentials() { # called right after shell_users_plan
    local cred="${GENERATED_CREDENTIALS:-}"
    [ -n "${cred}" ] || return 0

    # .env refresh: drop stale GENERATED_CREDENTIALS line, append current.
    if [ -f "${SERVER_DIR}/.env" ]; then
        grep -v '^GENERATED_CREDENTIALS=' "${SERVER_DIR}/.env" > "${SERVER_DIR}/.env.tmp" 2>/dev/null \
            || : > "${SERVER_DIR}/.env.tmp"
        mv "${SERVER_DIR}/.env.tmp" "${SERVER_DIR}/.env"
    else
        : > "${SERVER_DIR}/.env"
    fi
    printf 'GENERATED_CREDENTIALS=%s\n' "${cred}" >> "${SERVER_DIR}/.env"
    chmod 600 "${SERVER_DIR}/.env" 2>/dev/null || true

    # human-readable credential sheet (mode 600)
    mkdir -p "${SERVER_DIR}/.sh-users" 2>/dev/null || true
    {
        printf '# Multi-Shell Universal Egg - generated credentials\n'
        printf '# %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        local pair
        for pair in ${cred}; do
            printf '%s: %s\n' "${pair%%:*}" "${pair#*:}"
        done
    } > "${SERVER_DIR}/.sh-users/credentials"
    chmod 600 "${SERVER_DIR}/.sh-users/credentials" 2>/dev/null || true
    chmod 700 "${SERVER_DIR}/.sh-users" 2>/dev/null || true
}

# ---------------------------------------------------------------- reverse launch
launch_reverse_payloads() {
    local id path rhost rport
    read -r rhost rport <<< "$(reverse_target)"
    for id in "${SHELL_ENABLED_IDS[@]}"; do
        case "${id}" in
            ssh|ssh-cert|ssh-hardened|ssh-local|ssh-remote|ssh-dynamic|ssh-x11|rsync-ssh|sshfs|dropbear|telnetd|mosh-server|tmux|screen|zellij) continue ;;
        esac
        path="${REV_PAYLOAD_PATH[${id}]:-}"
        [ -n "${path}" ] && [ -f "${path}" ] || continue
        case "${id}" in
            wssh)     log "Launching $(reg_field "${id}" 1) -> ws://${rhost}:${rport}" ;;
            dnscat)   log "Launching $(reg_field "${id}" 1) -> DNS ${rhost}" ;;
            icmp-shell)
                if ! is_root; then warn "ICMP shell needs root/CAP_NET_RAW - skipping launch"; continue; fi
                log "Launching $(reg_field "${id}" 1) -> icmp to ${rhost}" ;;
            *)        log "Launching $(reg_field "${id}" 1) -> ${rhost}:${rport}" ;;
        esac
        setsid bash "${path}" >> "${SERVER_DIR}/logs/${id}.log" 2>&1 &
        CHILD_PIDS["${id}"]=$!
    done
}

# ---------------------------------------------------------------- supervisor
supervise_loop() {
    local id pid path sleep_mode="${SHELL_SUPERVISE_SLEEP:-5}"
    log "Supervisor online (interval ${sleep_mode}s). Managed services:"
    while true; do
        for id in "${SHELL_ENABLED_IDS[@]}"; do
            case "${id}" in
                ssh|ssh-cert|ssh-hardened|ssh-local|ssh-remote|ssh-dynamic|ssh-x11|rsync-ssh|sshfs|dropbear|telnetd|nc-bind|socat-bind|openssl-bind|php-bind|python-bind|ttyd|gotty|php-webshell|node-webshell)
                    pid="${CHILD_PIDS[${id}]:-}"
                    if [ -n "${pid}" ] && ! kill -0 "${pid}" 2>/dev/null; then
                        warn "$(reg_field "${id}" 1) died; restarting..."
                        local bind="${SHELL_ALLOCATED_PORTS[${id}]:-}"
                        [ -n "${bind}" ] && [ "${bind}" != "0" ] && export SHELL_BIND_PORT="${bind}"
                        "init_${id}" >/dev/null 2>&1 || true
                    fi
                    ;;
                *)
                    pid="${CHILD_PIDS[${id}]:-}"
                    if [ -n "${pid}" ] && ! kill -0 "${pid}" 2>/dev/null; then
                        warn "$(reg_field "${id}" 1) payload exited; restarting..."
                        "rev_start_${id//-/_}" >/dev/null 2>&1 || true
                        path="${REV_PAYLOAD_PATH[${id}]:-}"
                        [ -n "${path}" ] && [ -f "${path}" ] && {
                            setsid bash "${path}" >/dev/null 2>&1 &
                            CHILD_PIDS["${id}"]=$!
                        }
                    fi
                    ;;
            esac
        done
        sleep "${sleep_mode}"
    done
}

# ---------------------------------------------------------------- main
main() {
    log "Multi-Shell Universal Egg v${SHELL_EGGS_VERSION} - panel: ${PANEL_NAME:-unknown}"

    # 1. user plan (shared by ssh/dropbear/telnet)
    shell_users_plan
    persist_credentials

    # 2. resolve what to launch
    resolve_selection

    # 3. init handlers
    init_all_shells

    # 4. launch reverse payloads (init handlers only emitted them)
    launch_reverse_payloads

    # 5. connection guide
    print_connection_guide

    # 6. tty attach for multiplexers
    if [ "${SHELL_MUX_ATTACH:-auto}" = "auto" ] && [ "${TTY_INTERACTIVE:-0}" = "1" ] \
       && [ -n "${DEFAULT_SHELL_MUX:-}" ] && have "${DEFAULT_SHELL_MUX}"; then
        log "Attaching console to ${DEFAULT_SHELL_MUX} session (Ctrl-b d / Ctrl-a d to detach)..."
        case "${DEFAULT_SHELL_MUX}" in
            tmux)   exec tmux attach -t "${SHELL_MUX_SESSION:-shell-eggs}" 2>/dev/null || true ;;
            screen) exec screen -r "${SHELL_MUX_SESSION:-shell-eggs}" 2>/dev/null || true ;;
        esac
    fi

    # 7. supervise forever
    supervise_loop
}

main "$@"
