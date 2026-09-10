#!/usr/bin/env bash
# ============================================================================
#  PotenFYR Studios - Multi-Shell Universal Egg :: scripts/shell-picker.sh
#  AUTO-mode interactive picker with smooth full-screen pagination.
#  Flow: main menu -> category pages -> shell page -> port confirm ->
#        write ../.sh-autostart marker consumed by entrypoint.sh.
#  Non-interactive stdin: prints the catalog and exits cleanly.
#  Globals produced: PICK_TYPE (id), PICK_PORT, PICK_DESC, PICK_EXTRAS.
# ============================================================================
PICKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=shell-core.sh
source "${PICKER_DIR}/shell-core.sh"
# shellcheck source=shell-registry.sh
source "${PICKER_DIR}/shell-registry.sh"

MARKER_FILE="${PICKER_DIR}/../.sh-autostart"
PAGE_SIZE=8

PICK_TYPE=""
PICK_PORT=""
PICK_DESC=""
PICK_EXTRAS=""
PICK_ALL_CAT=""

# ---------------------------------------------------------------- ui helpers
C_DIM=$'\033[2m'; C_CYAN=$'\033[36m'; C_GREEN=$'\033[32m'
C_B=$'\033[1m'; C_R=$'\033[0m'

pick_header() {
    printf '\n%s+==========================================================+%s\n' "${C_CYAN}${C_B}" "${C_R}"
    printf '%s|%s%s  SHELL-EGGS INTERACTIVE PICKER%s%s - choose your shell%s\n' \
        "${C_CYAN}${C_B}" "${C_R}" "${C_B}" "${C_R}" "${C_DIM}" "${C_R}"
    printf '%s+==========================================================+%s\n\n' "${C_CYAN}${C_B}" "${C_R}"
}

pick_footer() { # pick_footer <hint>
    printf '\n%s%s%s\n%s>%s ' "${C_DIM}" "$1" "${C_R}" "${C_GREEN}${C_B}" "${C_R}"
}

CATEGORIES_ORDER=(server multiplexer reverse)
category_title() {
    case "$1" in
        server)      printf 'Incoming Shells - bind a port, connect in' ;;
        multiplexer) printf 'Multiplexers - persistent sessions' ;;
        reverse)     printf 'Reverse Shells - call back out to you' ;;
        *)           printf 'Shells' ;;
    esac
}
category_blurb() {
    case "$1" in
        server)      printf 'Listeners that accept incoming connections on a port.' ;;
        multiplexer) printf 'Keep sessions alive across disconnects. No port needed.' ;;
        reverse)     printf 'Shells that connect OUT to your listener (nc -lvnp). Try them all.' ;;
    esac
}
ids_in_category() {
    local id cat
    for id in "${REGISTRY_IDS[@]}"; do
        cat=$(reg_field "${id}" 2)
        [ "${cat}" = "$1" ] && printf '%s\n' "${id}"
    done
}

# ---------------------------------------------------------------- pager
# Sets PICK_TYPE to the chosen id, or PICK_ALL_CAT to the category when the
# user pressed 'a'. Returns 2 when the user wants to go back.
PAGINATE_CAT=""
paginate() { # paginate <title> <blurb> <items...>
    local title="$1" blurb="$2"; shift 2
    local items=("$@")
    local total=${#items[@]}
    [ "${total}" -eq 0 ] && return 1
    local page=0 max_page=$(( (total - 1) / PAGE_SIZE ))
    local i idx choice start end

    while true; do
        printf '\033[H\033[2J'
        pick_header
        printf '%s%s%s\n%s%s%s\n\n' "${C_B}" "${title}" "${C_R}" "${C_DIM}" "${blurb}" "${C_R}"

        start=$(( page * PAGE_SIZE ))
        end=$(( start + PAGE_SIZE - 1 ))
        [ "${end}" -ge "${total}" ] && end=$(( total - 1 ))

        for (( i = start; i <= end; i++ )); do
            idx=$(( i - start + 1 ))
            local id="${items[${i}]}"
            printf '  %s%2d)%s %-28s %s%s%s\n' \
                "${C_GREEN}${C_B}" "${idx}" "${C_R}" \
                "$(reg_field "${id}" 1)" \
                "${C_DIM}" "$(reg_field "${id}" 6)" "${C_R}"
        done

        printf '\n%s page %s of %s  ·  %s entries %s\n' "${C_DIM}" \
            "$((page + 1))" "$((max_page + 1))" "${total}" "${C_R}"

        local hint="number = select · n = next page · p = previous"
        [ "${max_page}" -gt 0 ] || hint="number = select"
        [ "${PICK_EXTRAS_DIRTY:-0}" = "0" ] || hint="${hint} · e = finish"
        pick_footer "${hint} · a = enable whole category · b = back · q = quit"

        PICK_TYPE=""; PICK_ALL_CAT=""
        IFS= read -r choice || { printf '\n'; return 1; }
        case "${choice}" in
            n|N) [ "${page}" -lt "${max_page}" ] && page=$(( page + 1 )) ;;
            p|P) [ "${page}" -gt 0 ] && page=$(( page - 1 )) ;;
            b|B) return 2 ;;
            q|Q) printf '%sBye.%s\n' "${C_DIM}" "${C_R}"; exit 0 ;;
            a|A) PICK_ALL_CAT="${PAGINATE_CAT}"; return 0 ;;
            ''|*[!0-9]*) : ;;
            *)
                if [ "${choice}" -ge 1 ] && [ "${choice}" -le $(( end - start + 1 )) ]; then
                    PICK_TYPE="${items[$(( start + choice - 1 ))]}"
                    return 0
                fi
                ;;
        esac
    done
}

# ---------------------------------------------------------------- port confirm
configure_single() { # configure_single <id>
    local id="$1" port port0 cat
    cat=$(reg_field "${id}" 2)
    port0=$(reg_field "${id}" 3)

    if [ "${port0}" = "0" ]; then
        PICK_PORT=""
        return 0
    fi

    printf '%s%s%s - bind port [%s%s%s]: ' \
        "${C_B}" "$(reg_field "${id}" 1)" "${C_R}" \
        "${C_GREEN}" "${SERVER_PORT:-${port0}}" "${C_R}"
    IFS= read -r port || return 1
    [ -n "${port}" ] || port="${SERVER_PORT:-${port0}}"
    case "${port}" in
        ''|*[!0-9]*) warn "Invalid port, using ${SERVER_PORT:-${port0}}"; port="${SERVER_PORT:-${port0}}" ;;
    esac
    PICK_PORT="${port}"
    return 0
}

marker_flush() { # marker_flush <extra-ids...>
    {
        printf 'SHELL_TYPE=%s\n' "${PICK_TYPE}"
        [ -n "${PICK_PORT}" ] && printf 'SHELL_BIND_PORT=%s\n' "${PICK_PORT}"
        [ -n "${PICK_DESC}" ] && printf 'SHELL_MODE_DESC=%s\n' "${PICK_DESC}"
        if [ "${#}" -gt 0 ]; then
            printf 'SHELL_EXTRA_TYPES=%s\n' "$*"
        fi
    } > "${MARKER_FILE}"
}

# ---------------------------------------------------------------- flows
main_menu() {
    printf '\033[H\033[2J'
    pick_header
    printf '%sHow do you want to reach this container?%s\n\n' "${C_B}" "${C_R}"
    printf '  %s 1)%s %sServer / incoming%s   - SSH, Dropbear, Telnet, Mosh bind a port you connect to\n' "${C_GREEN}" "${C_R}" "${C_B}" "${C_R}"
    printf '  %s 2)%s %sMultiplexer%s          - tmux / screen / zellij persistent sessions\n' "${C_GREEN}" "${C_R}" "${C_B}" "${C_R}"
    printf '  %s 3)%s %sReverse shell%s        - the container calls back to YOUR listener\n' "${C_GREEN}" "${C_R}" "${C_B}" "${C_R}"
    printf '  %s 4)%s %sBrowse everything%s    - page through the full catalog\n\n' "${C_GREEN}" "${C_R}" "${C_B}" "${C_R}"
    pick_footer "1-4"
}

flow_category() { # flow_category <cat>
    local items=() rc
    mapfile -t items < <(ids_in_category "$1")
    PAGINATE_CAT="$1"
    while true; do
        paginate "$(category_title "$1")" "$(category_blurb "$1")" "${items[@]}"; rc=$?
        case "${rc}" in
            1) return 1 ;;
            2) return 2 ;;
        esac
        if [ -n "${PICK_ALL_CAT}" ]; then
            PICK_TYPE="${items[0]}"
            PICK_PORT="${SERVER_PORT:-$(reg_field "${PICK_TYPE}" 3)}"
            PICK_DESC="all $(reg_field "${items[0]}" 2) shells enabled"
            shift # remaining args are extras
            [ "${#}" -gt 0 ] && PICK_EXTRAS="$*"
            marker_flush
            ok "Category mode: every '$(reg_field "${items[0]}" 2)' shell will launch on its own port."
            return 0
        fi
        configure_single "${PICK_TYPE}" || return 1
        PICK_DESC="chosen interactively ($(reg_field "${PICK_TYPE}" 1))"
        marker_flush
        ok "Selected: $(reg_field "${PICK_TYPE}" 1)${PICK_PORT:+ on port ${PICK_PORT}}"
        return 0
    done
}

flow_browse() {
    local cat rc
    for cat in "${CATEGORIES_ORDER[@]}"; do
        local items=()
        mapfile -t items < <(ids_in_category "${cat}")
        PAGINATE_CAT="${cat}"
        while true; do
            paginate "$(category_title "${cat}")" "$(category_blurb "${cat}")" "${items[@]}"; rc=$?
            case "${rc}" in
                1) return 1 ;;
                2) [ "${cat}" = "server" ] && { flow_browse; return $?; } ; return 2 ;;
            esac
            if [ -n "${PICK_ALL_CAT}" ]; then
                PICK_TYPE="${items[0]}"
                PICK_PORT="${SERVER_PORT:-$(reg_field "${PICK_TYPE}" 3)}"
                PICK_DESC="all $(reg_field "${items[0]}" 2) shells enabled"
                marker_flush
                return 0
            fi
            configure_single "${PICK_TYPE}" || return 1
            PICK_DESC="chosen interactively ($(reg_field "${PICK_TYPE}" 1))"
            marker_flush
            return 0
        done
    done
    return 0
}

# ---------------------------------------------------------------- catalog (non-tty)
print_catalog_and_exit() {
    pick_header
    local id
    for id in "${REGISTRY_IDS[@]}"; do
        printf '  %-14s %-12s port=%-6s root=%s  %s\n' \
            "${id}" "$(reg_field "${id}" 2)" "$(reg_field "${id}" 3)" \
            "$(reg_field "${id}" 4)" "$(reg_field "${id}" 6)"
    done
    printf '\n%sNon-interactive console detected: set SHELL_TYPE explicitly (e.g. ssh, python, socat).%s\n' "${C_DIM}" "${C_R}"
    exit 0
}

# ---------------------------------------------------------------- entry
if [ ! -t 0 ]; then
    print_catalog_and_exit
fi

while true; do
    main_menu
    IFS= read -r mode || exit 1
    case "${mode}" in
        1) flow_category server; rc=$? ;;
        2) flow_category multiplexer; rc=$? ;;
        3) flow_category reverse; rc=$? ;;
        4) flow_browse; rc=$? ;;
        q|Q) exit 0 ;;
        *) warn "Invalid choice"; continue ;;
    esac
    [ "${rc}" = "0" ] && break
done
exit 0
