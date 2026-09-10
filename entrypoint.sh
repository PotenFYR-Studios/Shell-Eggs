#!/usr/bin/env bash
# ============================================================================
#  PotenFYR Studios - Multi-Shell Universal Egg :: entrypoint.sh
#  One egg. Every shell. Every direction. Every panel.
#
#  Pterodactyl / Pelican / Feather / Wisp / Docker entrypoint.
#  Responsibilities (thin layer - all logic lives in run.sh + scripts/):
#    1. Panel detection (Pterodactyl/Pelican/Feather/Wisp/Docker/standalone)
#    2. Environment sync: egg variables -> .env persistence
#    3. AUTO mode interactive shell picker with smooth pagination
#    4. Boot card, banner, and exec into run.sh
#
#  PANEL DETECTION: Feather sets P_SERVER_UUID_SHORT, Pterodactyl/Pelican
#  expose P_SERVER_* + PeltD stack; bare Docker falls back to hostname shape.
# ============================================================================
set -u
umask 077

# ---------------------------------------------------------------- constants
SHELL_EGGS_VERSION="1.0.0"
EGG_REPO_RAW="https://raw.githubusercontent.com/PotenFYR-Studios/Shell-Eggs/main"
AUTOSTART_MARKER=".sh-autostart"
ENV_FILE="${ENV_FILE:-$PWD/.env}"
# Runtime scripts: panel installs put them in the server dir; the ghcr image
# ships them under /usr/local/bin/scripts.
if [ -d "${PWD}/scripts" ]; then
    SCRIPTS_DIR="${PWD}/scripts"
else
    SCRIPTS_DIR="/usr/local/bin/scripts"
fi
export SCRIPTS_DIR

# ---------------------------------------------------------------- ui state
if [ -t 0 ] && [ -t 1 ]; then
    TTY_INTERACTIVE=1
else
    TTY_INTERACTIVE=0
    export SHELL_EGGS_NON_INTERACTIVE=1
fi
CLI_THEME="${CLI_THEME:-sh}"
CLI_BANNER_GRADIENT="${CLI_BANNER_GRADIENT:-auto}"
export CLI_THEME CLI_BANNER_GRADIENT

# ---------------------------------------------------------------- egg defaults
# Panels inject these; bare Docker/standalone boots need them defined because
# the entrypoint runs with `set -u`.
: "${SHELL_TYPE:=auto}"
: "${SHELL_USERS:=}"
: "${SHELL_PASSWORDS:=}"
: "${AUTO_GENERATE_CREDENTIALS:=1}"
: "${SHELL_MOTD:=Welcome to the Multi-Shell Universal Egg (PotenFYR Studios).}"
: "${ENABLE_SFTP:=1}"
: "${SHELL_SFTP_SUBSYSTEM:=internal-sftp}"
: "${SHELL_ENABLE_NOTIFICATIONS:=0}"
: "${SHELL_NOTIFICATION_COMMAND:=}"
: "${AUTO_UPDATE_EGG:=1}"
: "${EGG_UPDATE_URL:=${EGG_REPO_RAW}/egg-shell-multi.json}"
: "${PANEL_STOP_WATCHER:=auto}"
export SHELL_TYPE SHELL_USERS SHELL_PASSWORDS AUTO_GENERATE_CREDENTIALS SHELL_MOTD \
       ENABLE_SFTP SHELL_SFTP_SUBSYSTEM SHELL_ENABLE_NOTIFICATIONS SHELL_NOTIFICATION_COMMAND \
       AUTO_UPDATE_EGG EGG_UPDATE_URL PANEL_STOP_WATCHER

# ---------------------------------------------------------------- logging
if [ "${CLI_THEME}" = "classic" ]; then
    log()  { printf '[PotenFYR] %s\n' "$*"; }
    ok()   { printf '[PotenFYR] OK: %s\n' "$*"; }
    warn() { printf '[PotenFYR] WARN: %s\n' "$*"; }
    fail() { printf '[PotenFYR] FAIL: %s\n' "$*"; }
else
    log()  { printf '\033[2m</>\033[0m \033[36mshell-eggs\033[0m %s\n' "$*"; }
    ok()   { printf '\033[2m</>\033[0m \033[36mshell-eggs\033[0m %s\n' "$*"; }
    warn() { printf '\033[2m</>\033[0m \033[33mshell-eggs\033[0m \033[33mWARN:\033[0m %s\n' "$*"; }
    fail() { printf '\033[2m</>\033[0m \033[31mshell-eggs\033[0m \033[31mFAIL:\033[0m %s\n' "$*"; }
fi

# ---------------------------------------------------------------- panel detect
detect_panel() {
    if [ -n "${P_SERVER_UUID_SHORT:-}" ]; then
        PANEL_NAME="Feather Panel"; PANEL_KIND="feather"
    elif [ -n "${P_SERVER_UUID:-}" ] && [ -n "${P_SERVER_PORT:-}" ]; then
        PANEL_NAME="Pterodactyl/Pelican"; PANEL_KIND="pterodactyl"
    elif [ -n "${SERVER_IP:-}" ] && [ -n "${SERVER_PORT:-}" ] && grep -qs 'docker\|containerd\|/docker/' /proc/1/cgroup 2>/dev/null; then
        PANEL_NAME="Docker"; PANEL_KIND="docker"
    else
        PANEL_NAME="Standalone/Docker"; PANEL_KIND="standalone"
    fi
}

# Port shims: every panel talks different variable names. Normalize once.
apply_port_shims() {
    if [ -n "${P_SERVER_IP:-}" ] && [ -z "${SERVER_IP:-}" ];    then SERVER_IP="${P_SERVER_IP}"; fi
    if [ -n "${P_SERVER_PORT:-}" ] && [ -z "${SERVER_PORT:-}" ]; then SERVER_PORT="${P_SERVER_PORT}"; fi
    if [ -z "${SERVER_IP:-}" ] || [ "${SERVER_IP:-}" = "0.0.0.0" ] || [ "${SERVER_IP:-}" = "1.1.1.1" ]; then
        SERVER_IP="0.0.0.0"
    fi
    export SERVER_IP SERVER_PORT
}

# ---------------------------------------------------------------- persistence
# Egg variables start with known prefixes; on every boot we mirror them into
# .env (mode 600) so credentials survive container recreation. Values already
# persisted win over generated ones (restarts never rotate secrets).
read_env_val() {
    sed -n "s/^${1}=//p" "${ENV_FILE}" 2>/dev/null | tail -n 1 | tr -d '\r'
}

apply_persisted() {
    [ -f "${ENV_FILE}" ] || { : > "${ENV_FILE}"; chmod 600 "${ENV_FILE}"; }
    local v
    for key in SHELL_TYPE SHELL_USERS SHELL_PASSWORDS AUTO_GENERATE_CREDENTIALS \
               SHELL_REFRESH_TOKENS SHELL_MOTD ENABLE_SFTP SHELL_SFTP_SUBSYSTEM \
               TELNET_BANNER SHELL_ENABLE_NOTIFICATIONS SHELL_NOTIFICATION_COMMAND \
               CLI_THEME CLI_BANNER_GRADIENT AUTO_UPDATE_EGG; do
        v=$(read_env_val "${key}")
        if [ -n "${v}" ]; then
            eval "export ${key}=\"\${v}\""
        fi
    done

    # Generated credential pairs recorded by run.sh (name=hash/metadata only).
    local creds
    creds=$(read_env_val "GENERATED_CREDENTIALS")
    if [ -n "${creds}" ]; then
        export GENERATED_CREDENTIALS="${creds}"
    fi
}

sync_env() {
    {
        printf 'SHELL_TYPE=%s\n'    "${SHELL_TYPE:-auto}"
        [ -n "${SHELL_USERS:-}" ]      && printf 'SHELL_USERS=%s\n' "${SHELL_USERS}"
        [ -n "${SHELL_PASSWORDS:-}" ]  && printf 'SHELL_PASSWORDS=%s\n' "${SHELL_PASSWORDS}"
        printf 'AUTO_GENERATE_CREDENTIALS=%s\n' "${AUTO_GENERATE_CREDENTIALS}"
        [ -n "${GENERATED_CREDENTIALS:-}" ] && printf 'GENERATED_CREDENTIALS=%s\n' "${GENERATED_CREDENTIALS}"
    } > "${ENV_FILE}"
    chmod 600 "${ENV_FILE}" 2>/dev/null || true
}

# ---------------------------------------------------------------- secrets
gen_rand() {
    local n="${1:-32}" s
    s=$(head -c 256 /dev/urandom 2>/dev/null | base64 | tr -d '/+=\n' | cut -c1-"${n}")
    if [ -z "${s}" ] || [ "${#s}" -lt "${n}" ]; then
        s=$(od -An -N64 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n' | cut -c1-"${n}")
    fi
    printf '%s' "${s:-changeMe$(date +%s)}"
}

# ---------------------------------------------------------------- banner
# SHELL ASCII-shadow art, 7 lines, printable width 66 columns. Gradient is
# applied per line; narrow consoles (<68 cols) get a compact one-liner.
SHELL_ART_LINES=(
'  ____  _          _ _    _____ '
' / ___|| |__   ___| | |  / ____|'
' \___ \| \ \ / / _ \ | | | (___  '
'  ___) | \ V /  __/ | |  \___ \ '
' |____/   \_/ \___|_|_|  _____) |'
'        |____/ '
)
print_banner() {
    local cols
    cols=$(tput cols 2>/dev/null || printf '80')
    if [ "${CLI_BANNER_GRADIENT}" = "none" ] || [ "${TTY_INTERACTIVE}" = "0" ]; then
        printf '== Multi-Shell Universal Egg v%s ==\n' "${SHELL_EGGS_VERSION}"
        return 0
    fi
    printf '\n'
    local gradients=(
        "36;1:94:96" "35;1:95:34" "33;1:93:31" "32;1:92:34" "31;1:91:35" "34;1:96:36"
    )
    local g pick
    if [ "${CLI_BANNER_GRADIENT}" = "auto" ]; then
        pick="${gradients[$((RANDOM % ${#gradients[@]}))]}"
    else
        case "${CLI_BANNER_GRADIENT}" in
            aurora)  pick="36;1:94:96" ;;
            candy)   pick="35;1:95:34" ;;
            citrus)  pick="33;1:93:31" ;;
            forest)  pick="32;1:92:34" ;;
            sunset)  pick="31;1:91:35" ;;
            ocean)   pick="34;1:96:36" ;;
            *)       pick="36;1:94:96" ;;
        esac
    fi
    IFS=':' read -r c1 c2 c3 <<< "${pick}"
    local i=0 line
    for line in "${SHELL_ART_LINES[@]}"; do
        local cc
        case $((i % 3)) in
            0) cc="${c1}" ;; 1) cc="${c2}" ;; 2) cc="${c3}" ;;
        esac
        printf '\033[%sm%s\033[0m\n' "${cc}" "${line}"
        i=$((i + 1))
    done
    printf '\033[2mOne egg. Every shell. Every direction. v%s :: PotenFYR Studios\033[0m\n\n' "${SHELL_EGGS_VERSION}"
}

# ---------------------------------------------------------------- boot card
_padrow() { # _padrow <label> <value>
    printf '  \033[36m%-18s\033[0m %s\n' "${1}" "${2}"
}
print_boot_card() {
    printf '\033[36m+----------------------------------------------------------+\033[0m\n'
    _padrow "Panel"       "${PANEL_NAME}"
    _padrow "Mode"        "${SHELL_MODE_DESC:-interactive AUTO picker}"
    _padrow "Shell"       "${SHELL_TYPE_RESOLVED:-${SHELL_TYPE}}"
    _padrow "Bind"        "${SHELL_BIND_IP:-0.0.0.0}:${SHELL_BIND_PORT:-${SERVER_PORT:-8888}}"
    _padrow "Users"       "${SHELL_USERS_DESC:-ask-on-connect}"
    _padrow "Extra Ports" "${EXTRA_PORTS_DESC:-none}"
    _padrow "Egg Version" "${SHELL_EGGS_VERSION}"
    printf '\033[36m+----------------------------------------------------------+\033[0m\n'
}

# ---------------------------------------------------------------- picker
pick_shell_interactive() {
    [ "${SHELL_EGGS_NON_INTERACTIVE:-0}" = "1" ] && return 0
    [ "${SHELL_TYPE:-auto}" != "auto" ] && return 0
    "${SCRIPTS_DIR}/shell-picker.sh" || return $?
    [ -f "${AUTOSTART_MARKER}" ] && . "${AUTOSTART_MARKER}"
    return 0
}

# ---------------------------------------------------------------- self-update
maybe_self_update() {
    [ "${AUTO_UPDATE_EGG:-1}" = "1" ] || return 0
    [ -n "${EGG_UPDATE_URL:-}" ] || return 0
    local tmp staged
    tmp=$(mktemp 2>/dev/null) || return 0
    if curl -fsSL --max-time 20 "${EGG_UPDATE_URL}" -o "${tmp}" 2>/dev/null \
       || wget -qT 20 "${EGG_UPDATE_URL}" -O "${tmp}" 2>/dev/null; then
        if grep -q "PotenFYR Studios" "${tmp}" 2>/dev/null; then
            staged="${PWD}/.entrypoint.sh.update"
            mv "${tmp}" "${staged}"
            chmod +x "${staged}"
            if bash -n "${staged}" 2>/dev/null; then
                log "Updated entrypoint from ${EGG_UPDATE_URL} (applies next boot)."
            else
                rm -f "${staged}"
                warn "Downloaded entrypoint failed syntax check; keeping current."
            fi
        fi
    fi
    rm -f "${tmp}" 2>/dev/null || true
}

# ---------------------------------------------------------------- main
main() {
    cd "${PWD}" || exit 1
    detect_panel
    apply_port_shims
    apply_persisted
    maybe_self_update

    print_banner
    log "Detected panel: ${PANEL_NAME}"
    log "Workspace: ${PWD}"

    pick_shell_interactive

    sync_env
    print_boot_card

    export PANEL_NAME PANEL_KIND SHELL_EGGS_VERSION
    exec bash "${SCRIPTS_DIR}/../run.sh"
}

main "$@"
