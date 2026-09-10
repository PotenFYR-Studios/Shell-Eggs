#!/usr/bin/env bash
# ============================================================================
#  PotenFYR Studios - Multi-Shell Universal Egg :: scripts/shell-core.sh
#  Shared helpers sourced by run.sh and every shell-init-*.sh handler.
# ============================================================================
SHELL_CORE_LOADED=1

# ---------------------------------------------------------------- logging
if [ "${CLI_THEME:-sh}" = "classic" ]; then
    log()  { printf '[PotenFYR] %s\n' "$*"; }
    ok()   { printf '[PotenFYR] OK: %s\n' "$*"; }
    warn() { printf '[PotenFYR] WARN: %s\n' "$*"; }
    fail() { printf '[PotenFYR] FAIL: %s\n' "$*"; }
else
    log()  { printf '\033[2m</>\033[0m \033[36mshell-eggs\033[0m %s\n' "$*"; }
    ok()   { printf '\033[2m</>\033[0m \033[36mshell-eggs\033[0m \033[32mOK:\033[0m %s\n' "$*"; }
    warn() { printf '\033[2m</>\033[0m \033[33mshell-eggs\033[0m \033[33mWARN:\033[0m %s\n' "$*"; }
    fail() { printf '\033[2m</>\033[0m \033[31mshell-eggs\033[0m \033[31mFAIL:\033[0m %s\n' "$*"; }
fi

have() { command -v "$1" >/dev/null 2>&1; }
is_root() { [ "$(id -u 2>/dev/null || echo 1)" = "0" ]; }

# ---------------------------------------------------------------- packages
# Best-effort runtime provisioning for stock images (yolks, plain debian).
# Our own ghcr image ships everything baked; this is the fallback path.
PKG_MGR=""
_detect_pkg_mgr() {
    if have apt-get; then PKG_MGR="apt"
    elif have apk; then PKG_MGR="apk"
    elif have dnf; then PKG_MGR="dnf"
    elif have yum; then PKG_MGR="yum"
    fi
}
pkg_install() {
    local missing=""
    local p
    for p in "$@"; do
        have "${p}" || missing="${missing} ${p}"
    done
    [ -n "${missing}" ] || return 0
    _detect_pkg_mgr
    if [ -z "${PKG_MGR}" ]; then
        warn "Packages missing and no package manager found:${missing}"
        return 1
    fi
    if ! is_root; then
        warn "Not root; cannot install:${missing} (use the shell-eggs ghcr image)"
        return 1
    fi
    log "Installing runtime packages:${missing}"
    case "${PKG_MGR}" in
        apt)
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq >/dev/null 2>&1 || true
            apt-get install -y -qq --no-install-recommends ${missing} >/dev/null 2>&1 || \
                apt-get install -y -qq --no-install-recommends ${missing} || return 1
            ;;
        apk) apk add --no-cache ${missing} >/dev/null 2>&1 || return 1 ;;
        dnf) dnf install -y -q ${missing} >/dev/null 2>&1 || return 1 ;;
        yum) yum install -y -q ${missing} >/dev/null 2>&1 || return 1 ;;
    esac
    return 0
}

# ---------------------------------------------------------------- ports
# Port map: SHELL_ALLOCATED_PORTS["<id>"]=port. Primary shell gets SERVER_PORT;
# extras come from SHELL_EXTRA_PORTS positionally, then auto-increment.
declare -A SHELL_ALLOCATED_PORTS
SHELL_AUTO_PORT_STEP=${SHELL_AUTO_PORT_STEP:-1}

port_in_use() {
    local port="$1"
    if have ss; then
        ss -ltn 2>/dev/null | awk '{print $4}' | grep -qE "[:.]${port}$" && return 0
    fi
    if have netstat; then
        netstat -ltn 2>/dev/null | awk '{print $4}' | grep -qE "[:.]${port}$" && return 0
    fi
    # /proc/net/tcp check (hex, works everywhere)
    local hex
    hex=$(printf '%04X' "${port}" 2>/dev/null) || return 1
    awk '{print $2}' /proc/net/tcp /proc/net/tcp6 2>/dev/null | grep -qi ":${hex}$"
}

allocate_port() { # allocate_port <id> <preferred>
    local id="$1" preferred="${2:-${SERVER_PORT:-8888}}" port="${2:-${SERVER_PORT:-8888}}"
    if [ -n "${SHELL_ALLOCATED_PORTS[${id}]:-}" ]; then
        printf '%s\n' "${SHELL_ALLOCATED_PORTS[${id}]}"
        return 0
    fi
    if port_in_use "${port}"; then
        local p
        for p in $(seq 10 60); do
            port=$(( preferred + p ))
            port_in_use "${port}" || break
        done
        warn "Port ${preferred} busy; auto-allocated ${port} for ${id}"
    fi
    SHELL_ALLOCATED_PORTS["${id}"]="${port}"
    printf '%s\n' "${port}"
}

# ---------------------------------------------------------------- registry
declare -A REGISTRY_META   # id -> "display|category|default_port|needs_root|description"
REGISTRY_IDS=()
register_shell() { # register_shell <id> <display> <category> <port> <needs_root> <desc>
    local id="$1"
    REGISTRY_META["${id}"]="${2}|${3}|${4}|${5}|${6}"
    case " ${REGISTRY_IDS[*]} " in
        *" ${id} "*) : ;;
        *) REGISTRY_IDS+=("${id}") ;;
    esac
}
reg_field() { # reg_field <id> <1..5>
    local m="${REGISTRY_META[${1}]:-||||}"
    printf '%s\n' "$(printf '%s' "${m}" | cut -d'|' -f"${2}")"
}

# ---------------------------------------------------------------- selection
SHELL_ENABLED_IDS=()          # launch order
declare -A SHELL_START_FN     # id -> start function name
declare -A SHELL_DESC_EXTRA   # id -> extra connection note

shell_enable() { # shell_enable <id> <start_fn>
    local id
    for id in "${SHELL_ENABLED_IDS[@]:-}"; do
        [ "${id}" = "$1" ] && return 0   # already enabled - never duplicate
    done
    SHELL_ENABLED_IDS+=("$1")
    SHELL_START_FN["$1"]="$2"
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

# ---------------------------------------------------------------- users
# Multi-user plan: SHELL_USERS + SHELL_PASSWORDS (positional), auto-generate
# missing secrets, persist GENERATED_CREDENTIALS across restarts.
SHELL_PLAN_USERS=()
SHELL_PLAN_PASSWORDS=()

cred_line() { # cred_line <user> -> persisted "user:pass" or empty
    local c
    for c in ${GENERATED_CREDENTIALS:-}; do
        [ "${c%%:*}" = "$1" ] && { printf '%s\n' "${c#*:}"; return 0; }
    done
    return 1
}

remember_cred() { # remember_cred <user> <pass>
    local out="" c found=0
    for c in ${GENERATED_CREDENTIALS:-}; do
        if [ "${c%%:*}" = "$1" ]; then
            out="${out} $1:$2"; found=1
        else
            out="${out} ${c}"
        fi
    done
    [ "${found}" = "0" ] && out="${GENERATED_CREDENTIALS:-} $1:$2"
    export GENERATED_CREDENTIALS="${out# }"
}

shell_users_plan() {
    local users="${SHELL_USERS:-}"
    local passes="${SHELL_PASSWORDS:-}"
    local gen="${AUTO_GENERATE_CREDENTIALS:-1}"
    local i u p gen_pass

    if [ -z "${users}" ]; then
        users="root-user"
    fi

    IFS=',' read -r -a _USERS_TMP <<< "${users}"
    IFS=',' read -r -a _PASSES_TMP <<< "${passes}"

    SHELL_PLAN_USERS=()
    SHELL_PLAN_PASSWORDS=()
    for i in "${!_USERS_TMP[@]}"; do
        u="${_USERS_TMP[${i}]}"
        u="${u// /}"
        [ -n "${u}" ] || continue
        if printf '%s' "${u}" | grep -qE '[^A-Za-z0-9._@-]'; then
            warn "Skipping invalid username '${u}' (allowed: A-Z a-z 0-9 . _ @ -)"
            continue
        fi
        p="${_PASSES_TMP[${i}]:-}"
        if [ -z "${p}" ] || [ "${p}" = "auto" ]; then
            gen_pass=1
        else
            gen_pass=0
        fi
        if [ "${gen_pass}" = "1" ]; then
            if [ "${gen}" = "1" ]; then
                p=$(cred_line "${u}" || true)
                if [ -z "${p}" ]; then
                    p=$(gen_rand 24)
                fi
                remember_cred "${u}" "${p}"
            else
                p=$(cred_line "${u}" || printf '')
                if [ -z "${p}" ]; then
                    warn "User '${u}' has no password and AUTO_GENERATE_CREDENTIALS=0"
                fi
            fi
        fi
        SHELL_PLAN_USERS+=("${u}")
        SHELL_PLAN_PASSWORDS+=("${p}")
    done
}

os_arch() {
    case "$(uname -m)" in
        x86_64|amd64) printf 'amd64' ;;
        aarch64|arm64) printf 'arm64' ;;
        armv7l|armhf) printf 'arm' ;;
        riscv64) printf 'riscv64' ;;
        s390x) printf 's390x' ;;
        ppc64le) printf 'ppc64le' ;;
        *) uname -m ;;
    esac
}

# ---------------------------------------------------------------- misc
write_motd_file() { # write_motd_file <path>
    {
        printf '%s\n' "${SHELL_MOTD:-Welcome to the Multi-Shell Universal Egg (PotenFYR Studios).}"
        printf '%s\n' "Authorized use only. All sessions may be logged."
    } > "$1" 2>/dev/null || true
}
