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
    *)
        # Panels never open fd 3 for us - dup console stdin to the watch fd in
        # THIS shell before backgrounding, or the watcher dies instantly with
        # "bad file descriptor" and panel stop-as-text is never seen. Probe in
        # a subshell first: a failed exec redirection would exit the launcher
        # when stdin is closed. NOTE: exec redirections are PERMANENT for the
        # shell - never add `2>/dev/null` here, that silently re-pointed the
        # launcher's stderr to /dev/null for the whole run.
        if ( eval "exec ${WATCH_STOP_FD}<&0" ) 2>/dev/null; then
            eval "exec ${WATCH_STOP_FD}<&0"
            eval "watch_panel_stop ${WATCH_STOP_FD} & WATCHER_PID=\$!"
        fi
        ;;
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
        #   The PRIMARY inbound port is always the server's assigned port
        #   (SERVER_PORT / P_SERVER_PORT). Catalog defaults like 4444/5555 are
        #   only fallbacks for bare-docker runs without SERVER_PORT set -
        #   panel-allocated ports take absolute priority because 22/23/4444
        #   are rarely allocatable.
        #   Extra ported shells consume SHELL_EXTRA_PORTS positionally, then
        #   auto-allocate above the primary port.
        local bind
        if [ "${port0}" != "0" ]; then
            if [ "${first_port_set}" = "0" ]; then
                bind="${SERVER_PORT:-${port0}}"
                if [ -n "${SERVER_PORT:-}" ]; then
                    log "${id}: binding the server's primary port ${SERVER_PORT} (panel-assigned)."
                fi
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
        local payload_interp="bash"
        case "${id}" in
            python|python-pty|wssh) payload_interp="python3" ;;
            golang)                 continue ;;   # go sources need compilation; skip auto-run
        esac
        case "${payload_interp}" in
            python3) setsid python3 "${path}" >> "${SERVER_DIR}/logs/${id}.log" 2>&1 & ;;
            *)       setsid bash "${path}" >> "${SERVER_DIR}/logs/${id}.log" 2>&1 & ;;
        esac
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
                        [ -n "${path}" ] && [ -f "${path}" ] || continue
                        local payload_interp="bash"
                        case "${id}" in
                            python|python-pty|wssh) payload_interp="python3" ;;
                            golang)                 continue ;;
                        esac
                        case "${payload_interp}" in
                            python3) setsid python3 "${path}" >/dev/null 2>&1 & ;;
                            *)       setsid bash "${path}" >/dev/null 2>&1 & ;;
                        esac
                        CHILD_PIDS["${id}"]=$!
                    fi
                    ;;
            esac
        done
        sleep "${sleep_mode}"
    done
}


# ---------------------------------------------------------------- git sync
# Git Repository Sync (GIT_REPO_URL / GIT_BRANCH / GIT_TOKEN)
# ---------------------------------------------------------------------------
# Clones/updates a user Git repository into the server directory on startup -
# keep your own tooling, scripts and dotfiles versioned in git.
#
# Startup variables (defined in egg-shell-multi.json):
#   GIT_REPO_URL          - https GitHub URL or 'owner/repo' shorthand (user)
#   GIT_BRANCH            - branch to track (empty = repo default)          (user)
#   GIT_TOKEN             - access token; injected by admins only          (admin)
#   GIT_ARCHIVE_ON_UPDATE - 1 = snapshot old files into ./archive/git-sync/
#                           before applying new commits (default 1)
#   GIT_AUTO_UPDATE       - 1 = poll while running and sync new commits
#                           (a restart re-sources them; nothing is killed
#                           automatically) (default 1)
#   GIT_POLL_SECONDS      - poll cadence, 30-86400 (default 300)
#
# Design notes:
#   * Manifest-based: the repo is cloned into a throwaway staging dir and the
#     workspace never holds a .git, so ownership mismatches and stale git
#     locks cannot break updates.
#   * File-level manifest: only files the repo previously shipped are removed
#     on update, so anything else in the workspace is never touched.
#   * A revoked/expired token falls back to anonymous download for PUBLIC
#     repositories instead of failing the whole sync.
#   * Failure of any step is non-fatal: previously synced files keep running.
# ---------------------------------------------------------------------------
declare -F phase >/dev/null 2>&1 || phase() { printf '\n== %s ==\n' "$*"; }

_PF_SYNC_PROTECTED='.env
.profile
.bashrc
scripts
logs
payloads
archive
.logs
.runtimes
.git-sync'

_pf_sync_is_protected() { # _pf_sync_is_protected <relative-path>
    local seg="${1%%/*}" rest
    case "${seg}" in
        .|..|"") return 0 ;;
    esac
    while IFS= read -r rest; do
        [ "${seg}" = "${rest}" ] && return 0
    done <<EOF
${_PF_SYNC_PROTECTED}
EOF
    return 1
}

# ---------------------------------------------------------------------------
# GIT_PRESERVE_ENV (default 1): credentials must survive repo updates. Every
# .env currently in the workspace is snapshotted before the new tree lands
# and copied back to its original location afterwards, so a repo-shipped .env
# can never clobber or wipe live credentials and the shell setup keeps
# working. Set GIT_PRESERVE_ENV=0 to let the repository's .env files win.
_pf_sync_preserve_env_enabled() {
    [ "${GIT_PRESERVE_ENV:-1}" = "1" ]
}

_pf_sync_snapshot_env() { # _pf_sync_snapshot_env <workspace> <backup-dir>
    _pf_sync_preserve_env_enabled || return 0
    rm -rf "$2" 2>/dev/null || true
    mkdir -p "$2" 2>/dev/null || return 0
    ( cd "$1" 2>/dev/null || exit 0
      find . -type f -name .env -not -path './archive/*' -not -path './.git-sync/*' \
             -not -path './.runtimes/*' -not -path './node_modules/*' 2>/dev/null | sed 's#^\./##'
    ) 2>/dev/null | while IFS= read -r _rel; do
        [ -n "${_rel}" ] || continue
        mkdir -p "$2/$(dirname "${_rel}")" 2>/dev/null || true
        cp -f "$1/${_rel}" "$2/${_rel}" 2>/dev/null || true
    done
}

_pf_sync_restore_env() { # _pf_sync_restore_env <workspace> <backup-dir>
    _pf_sync_preserve_env_enabled || return 0
    [ -d "$2" ] || return 0
    local _restored=0 _rel
    while IFS= read -r _rel; do
        [ -n "${_rel}" ] || continue
        mkdir -p "$1/$(dirname "${_rel}")" 2>/dev/null || true
        if cp -f "$2/${_rel}" "$1/${_rel}" 2>/dev/null; then
            _restored=$((_restored + 1))
        fi
    done < <( cd "$2" 2>/dev/null && find . -type f 2>/dev/null | sed 's#^\./##' )
    if [ "${_restored}" -gt 0 ]; then
        ok "Preserved ${_restored} existing .env file(s) across the update (GIT_PRESERVE_ENV)."
    fi
    rm -rf "$2" 2>/dev/null || true
    return 0
}

# ---------------------------------------------------------------------------
# GIT_EXCLUDE: user-configurable, whitespace/comma-separated glob patterns
# (matched against repo-relative paths) that git sync must never install or
# overwrite - e.g. GIT_EXCLUDE="payloads/custom/* secrets". Everything else
# is synced normally.
_pf_sync_is_user_excluded() { # _pf_sync_is_user_excluded <relative-path>
    local _pat
    local _list="${GIT_EXCLUDE:-}"
    for _pat in ${_list//,/ }; do
        case "${1}" in
            ${_pat}|${_pat}/*) return 0 ;;
        esac
    done
    return 1
}

# Accepts 'owner/repo', 'https://github.com/owner/repo(.git)', with optional
# 'git@github.com:owner/repo.git' SSH form rewritten to https. file:// and
# loopback http(s) URLs pass through untouched (self-hosted Git/Gitea + tests).
_pf_sync_normalize_url() {
    local raw="$1" url kind="generic" host
    raw="${raw%%#*}"; raw="${raw%%\?*}"
    raw="${raw%.git}"
    case "${raw}" in
        file://*)
            printf '%s generic\n' "${raw}"; return 0 ;;
        http://localhost[:/]*|http://127.0.0.1[:/]*|https://localhost[:/]*|https://127.0.0.1[:/]*)
            printf '%s generic\n' "${raw}"; return 0 ;;
        http://*)  raw="${raw#http://}" ;;
        https://*) raw="${raw#https://}" ;;
        ssh://*)   raw="${raw#ssh://}" ;;
        git@*)     raw="${raw#git@}"; raw="${raw/://}" ;;   # git@host:o/r -> host/o/r
    esac
    host="${raw%%/*}"
    case "${host}" in
        *.*|*:*|localhost) : ;;              # already a hostname
        *) raw="github.com/${raw}" ;;        # bare owner/repo shorthand
    esac
    url="https://${raw}"
    case "${url}" in
        https://github.com/*) kind="github" ;;
    esac
    printf '%s %s\n' "${url}" "${kind}"
}

_pf_sync_auth_header() { # prints curl-style auth header when a token is set
    if [ -n "${GIT_TOKEN:-}" ]; then
        printf 'Authorization: Bearer %s\n' "${GIT_TOKEN}"
    fi
}

# Isolated global git config (safe.directory) so git never refuses a staging
# dir over an owner mismatch on root-installed images.
_pf_sync_git_env() {
    if [ -z "${GIT_CONFIG_GLOBAL:-}" ]; then
        local _cfg
        _cfg="$(mktemp 2>/dev/null || echo "/tmp/potenfyr-gitconfig.$$")"
        {
            [ -f "${HOME}/.gitconfig" ] && cat "${HOME}/.gitconfig" 2>/dev/null
            printf '[safe]\n\tdirectory = *\n'
            printf '[init]\n\tdefaultBranch = main\n'
        } > "${_cfg}" 2>/dev/null || true
        export GIT_CONFIG_GLOBAL="${_cfg}"
    fi
}

_pf_sync_git_auth() { # prints git -c args; pass "anon" to skip auth
    if [ "${1:-}" != "anon" ] && [ -n "${GIT_TOKEN:-}" ]; then
        printf '%s\n' "-c" "http.extraheader=Authorization: Basic $(printf 'x-access-token:%s' "${GIT_TOKEN}" | base64 2>/dev/null | tr -d '\n')"
    fi
}

# Latest remote commit sha for the tracked branch (git ls-remote, with an
# authenticated attempt first and an anonymous retry for public repos).
_pf_sync_remote_head() { # _pf_sync_remote_head <url> <kind> <branch>
    local url="$1" kind="$2" branch="$3" sha=""
    if command -v git >/dev/null 2>&1; then
        local reflist
        _pf_sync_git_env
        local ref="HEAD"
        [ -n "${branch}" ] && ref="refs/heads/${branch}"
        reflist=$(git $(_pf_sync_git_auth) ls-remote "${url}" "${ref}" 2>/dev/null)
        if [ -z "${reflist}" ] && [ -n "${GIT_TOKEN:-}" ]; then
            reflist=$(git $(_pf_sync_git_auth anon) ls-remote "${url}" "${ref}" 2>/dev/null)
        fi
        sha=$(printf '%s' "${reflist}" | awk 'NR==1{print $1}')
        if [ -z "${sha}" ] && [ -z "${branch}" ]; then
            sha=$(git $(_pf_sync_git_auth) ls-remote "${url}" 2>/dev/null | awk '/refs\/heads\//{print $1; exit}')
        fi
        [ -n "${sha}" ] && { printf '%s' "${sha}"; return 0; }
    fi
    case "${kind}" in
        github)
            local repo_path="${url#https://github.com/}" api commit_body
            api="https://api.github.com/repos/${repo_path}"
            [ -n "${branch}" ] && api="${api}/commits/${branch}" || api="${api}/commits/HEAD"
            commit_body=$(_pf_fetch "${api}") || return 1
            sha=$(printf '%s' "${commit_body}" | _json_field '"sha"')
            [ -n "${sha}" ] || return 1
            printf '%s' "${sha}"
            return 0
            ;;
    esac
    return 1
}

_pf_fetch() { # _pf_fetch <url> [outfile]
    local url="$1" out="${2:--}"
    local hdr
    hdr=$(_pf_sync_auth_header)
    if command -v curl >/dev/null 2>&1; then
        if [ "${out}" = "-" ]; then
            [ -n "${hdr}" ] && curl -fsSL --retry 2 --max-time 60 -H "${hdr}" "${url}" 2>/dev/null \
                || curl -fsSL --retry 2 --max-time 60 "${url}" 2>/dev/null
        else
            { [ -n "${hdr}" ] && curl -fsSL --retry 2 --max-time 120 -H "${hdr}" -o "${out}" "${url}" 2>/dev/null \
                || curl -fsSL --retry 2 --max-time 120 -o "${out}" "${url}" 2>/dev/null; } && [ -s "${out}" ]
        fi
    elif command -v wget >/dev/null 2>&1; then
        if [ "${out}" = "-" ]; then
            [ -n "${hdr}" ] && wget -qO- --header "${hdr}" "${url}" 2>/dev/null || wget -qO- "${url}" 2>/dev/null
        else
            { [ -n "${hdr}" ] && wget -qO "${out}" --header "${hdr}" "${url}" 2>/dev/null \
                || wget -qO "${out}" "${url}" 2>/dev/null; } && [ -s "${out}" ]
        fi
    else
        return 127
    fi
}

_json_field() {
    grep -oE "${1}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -n1 | sed -E "s/.*\"[^\"]*\"[[:space:]]*:[[:space:]]*\"([^\"]*)\".*/\1/"
}

_pf_sync_tarball() { # _pf_sync_tarball <url> <kind> <branch> <dest-dir>
    local url="$1" kind="$2" branch="$3" dest="$4" tmp turl
    tmp=$(mktemp 2>/dev/null) || return 1
    case "${kind}" in
        github)
            local repo_path="${url#https://github.com/}"
            if [ -n "${branch}" ]; then
                turl="https://codeload.github.com/${repo_path}/tar.gz/refs/heads/${branch}"
            else
                turl="https://codeload.github.com/${repo_path}/tar.gz"
            fi
            ;;
        *)
            rm -f "${tmp}"; return 1 ;;   # generic hosts require the git binary
    esac
    if ! _pf_fetch "${turl}" "${tmp}"; then
        rm -f "${tmp}"; return 1
    fi
    mkdir -p "${dest}"
    if ! tar -xzf "${tmp}" -C "${dest}" --strip-components=1 2>/dev/null; then
        rm -rf "${dest}" "${tmp}"; return 1
    fi
    rm -f "${tmp}"
    return 0
}

sync_git_repo() {
    [ -n "${GIT_REPO_URL:-}" ] || return 0

    local url kind branch
    { read -r url kind <<< "$(_pf_sync_normalize_url "${GIT_REPO_URL}")"; } || return 0
    [ -n "${url}" ] || return 0
    branch="${GIT_BRANCH:-}"
    branch="${branch//[$'\r\n']/}"
    branch="${branch##refs/heads/}"

    local state_dir="${SERVER_DIR:-$PWD}/.git-sync"
    mkdir -p "${state_dir}" 2>/dev/null || { warn "Git sync: cannot create state dir; skipping."; return 0; }

    local m_repo="${state_dir}/repo" m_branch="${state_dir}/branch" m_commit="${state_dir}/commit" m_manifest="${state_dir}/manifest"
    local last_repo last_branch last_commit
    last_repo="$(cat "${m_repo}" 2>/dev/null || true)"
    last_branch="$(cat "${m_branch}" 2>/dev/null || true)"
    last_commit="$(cat "${m_commit}" 2>/dev/null || true)"
    local has_manifest=0
    [ -s "${m_manifest}" ] && has_manifest=1

    phase "Git Repository Sync"
    log "Checking ${url}$([ -n "${branch}" ] && printf ' (branch: %s)' "${branch}")..."

    local remote_head
    if ! remote_head=$(_pf_sync_remote_head "${url}" "${kind}" "${branch}"); then
        if [ "${has_manifest}" = "1" ]; then
            warn "Could not reach the repository - keeping previously synced files (commit ${last_commit:-unknown})."
        else
            warn "Could not reach the repository and no synced files exist yet - continuing without repo content."
        fi
        return 1
    fi

    # Up to date: same repo, same commit, files actually still present.
    if [ "${has_manifest}" = "1" ] && [ "${last_repo}" = "${url}" ] \
       && [ -n "${remote_head}" ] && [ "${last_commit}" = "${remote_head}" ]; then
        local mf present=0
        while IFS= read -r mf; do
            [ -n "${mf}" ] && [ -e "${SERVER_DIR:-$PWD}/${mf}" ] && { present=1; break; }
        done < "${m_manifest}"
        if [ "${present}" = "1" ]; then
            ok "Repository files are up to date (commit ${remote_head:0:9})."
            return 0
        fi
        warn "Synced files are missing from the workspace although the commit matches - re-downloading."
    fi

    # --- Update path: archive currently synced files before replacing --------
    local f
    if [ "${has_manifest}" = "1" ] && [ -n "${last_commit}" ]; then
        if [ "${last_repo}" != "${url}" ]; then
            warn "Repository changed (${last_repo:-none} -> ${url}) - replacing synced files."
        else
            log "New commits detected (${last_commit:0:9} -> ${remote_head:0:9})."
        fi
        if [ "${GIT_ARCHIVE_ON_UPDATE:-1}" = "1" ]; then
            local adir="${SERVER_DIR:-$PWD}/archive/git-sync" ts out
            mkdir -p "${adir}" 2>/dev/null || true
            ts=$(date -u +%Y%m%d-%H%M%S 2>/dev/null || echo manual)
            out="${adir}/files-${ts}.tar.gz"
            local -a files=()
            while IFS= read -r f; do
                [ -n "${f}" ] && [ -e "${SERVER_DIR:-$PWD}/${f}" ] && files+=("${f}")
            done < "${m_manifest}"
            if [ "${#files[@]}" -gt 0 ]; then
                if tar -czf "${out}.tmp" -C "${SERVER_DIR:-$PWD}" "${files[@]}" 2>/dev/null && [ -s "${out}.tmp" ]; then
                    mv -f "${out}.tmp" "${out}"
                    ok "Archived previous files -> ${out#"${SERVER_DIR:-$PWD}"/}"
                else
                    rm -f "${out}.tmp" 2>/dev/null || true
                    warn "Could not archive previous files - update aborted (old files kept)."
                    return 1
                fi
            fi
        fi
        # Remove previously synced files so upstream deletions propagate.
        while IFS= read -r f; do
            [ -n "${f}" ] || continue
            _pf_sync_is_protected "${f}" && continue
            rm -f "${SERVER_DIR:-$PWD}/${f}" 2>/dev/null || true
        done < "${m_manifest}"
    fi

    # --- Download fresh tree into a staging dir ------------------------------
    local stage
    stage=$(mktemp -d 2>/dev/null) || { warn "Git sync: mktemp failed - keeping current files."; return 1; }
    local dl_ok=0
    if command -v git >/dev/null 2>&1; then
        _pf_sync_git_env
        local -a clone_args=(--depth 1 --single-branch)
        [ -n "${branch}" ] && clone_args+=(--branch "${branch}")
        if git $(_pf_sync_git_auth) clone "${clone_args[@]}" "${url}" "${stage}/repo" >/dev/null 2>&1; then
            :
        elif [ -n "${GIT_TOKEN:-}" ] \
                && git $(_pf_sync_git_auth anon) clone "${clone_args[@]}" "${url}" "${stage}/repo" >/dev/null 2>&1; then
            warn "Authenticated download failed - public repository synced without the token (check GIT_TOKEN)."
        fi
        if [ -d "${stage}/repo" ]; then
            rm -rf "${stage}/repo/.git" 2>/dev/null || true
            mkdir -p "${stage}/out"
            if ( cd "${stage}/repo" && shopt -s dotglob nullglob && \
                 items=( * ); [ "${#items[@]}" -eq 0 ] || cp -a -- "${items[@]}" "${stage}/out"/ ); then
                dl_ok=1
            fi
        fi
    fi
    if [ "${dl_ok}" != "1" ]; then
        if _pf_sync_tarball "${url}" "${kind}" "${branch}" "${stage}/out"; then
            dl_ok=1
        else
            rm -rf "${stage}"
            if [ "${has_manifest}" = "1" ]; then
                warn "Download failed - previous files kept (commit ${last_commit})."
            else
                warn "Download failed - continuing without repo content."
            fi
            return 1
        fi
    fi

    # --- Install staged tree into the workspace (file-level manifest) --------
    _pf_sync_snapshot_env "${SERVER_DIR:-$PWD}" "${state_dir}/env-backup"
    local new_manifest="${state_dir}/.manifest.new"
    : > "${new_manifest}" 2>/dev/null || true
    local rel
    (
        cd "${stage}/out" 2>/dev/null || exit 1
        find . -type f -o -type l
    ) 2>/dev/null | sed 's#^\./##' | sort | while IFS= read -r rel; do
        [ -n "${rel}" ] || continue
        if _pf_sync_is_protected "${rel}"; then
            warn "Git sync: skipping protected path '${rel}' (managed by the runtime)."
            continue
        fi
        if _pf_sync_is_user_excluded "${rel}"; then
            warn "Git sync: skipping '${rel}' (matched GIT_EXCLUDE)."
            continue
        fi
        mkdir -p "${SERVER_DIR:-$PWD}/$(dirname "${rel}")" 2>/dev/null || true
        if cp -a "${stage}/out/${rel}" "${SERVER_DIR:-$PWD}/${rel}" 2>/dev/null; then
            printf '%s\n' "${rel}" >> "${new_manifest}"
        fi
    done
    _pf_sync_restore_env "${SERVER_DIR:-$PWD}" "${state_dir}/env-backup"

    if [ -s "${new_manifest}" ]; then
        mv -f "${new_manifest}" "${m_manifest}" 2>/dev/null || true
        printf '%s\n' "${url}" > "${m_repo}"
        printf '%s\n' "${branch}" > "${m_branch}"
        printf '%s\n' "${remote_head}" > "${m_commit}"
        ok "Repository files installed at commit ${remote_head:0:9} (branch: ${branch:-default})."
    else
        rm -f "${new_manifest}"
        warn "Nothing was extracted from the repository (empty tree?) - workspace left unchanged."
        return 1
    fi
    rm -rf "${stage}" 2>/dev/null || true
    return 0
}

run_git_update_watcher() {
    local poll="${GIT_POLL_SECONDS:-300}"
    case "${poll}" in ''|*[!0-9]*) poll=300 ;; esac
    [ "${poll}" -lt 30 ] && poll=30
    [ "${poll}" -gt 86400 ] && poll=86400
    while :; do
        sleep "${poll}"
        sync_git_repo >/dev/null 2>&1 || true
    done
}

start_git_update_watcher() {
    [ "${GIT_AUTO_UPDATE:-1}" = "1" ] || return 0
    [ -n "${GIT_REPO_URL:-}" ] || return 0
    command -v git >/dev/null 2>&1 || return 0
    (
        run_git_update_watcher
    ) &
    GIT_AUTO_UPDATE_PID=$!
    ok "Git Auto-Update watcher active (polling every ${GIT_POLL_SECONDS:-300}s; new commits are synced - restart to re-source them)."
}

# ---------------------------------------------------------------- main
main() {
    log "Multi-Shell Universal Egg v${SHELL_EGGS_VERSION} - panel: ${PANEL_NAME:-unknown}"

    # 0. git repository sync (optional; see the engine block above)
    sync_git_repo || true
    start_git_update_watcher

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
