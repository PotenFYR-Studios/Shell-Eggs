#!/usr/bin/env bash
# ============================================================================
#  PotenFYR Studios - Multi-Shell Universal Egg :: scripts/shell-init-mux.sh
#  Multiplexer handlers: init_tmux, init_screen, init_zellij.
#  Multiplexers do not bind ports; the egg keeps a detached session alive and
#  offers an in-console attach (tty mode). They also serve as connection
#  targets: set DEFAULT_SHELL_MUX so ssh/telnet logins land inside the mux.
# ============================================================================
# shellcheck source=shell-core.sh
[ -n "${SHELL_CORE_LOADED:-}" ] || source "${SCRIPTS_DIR}/shell-core.sh"

mux_common_ensure() { # mux_common_ensure <binary> <pkg> <script-name>
    local bin="$1" pkg="$2"
    if ! have "${bin}"; then
        pkg_install "${pkg}" || true
    fi
    have "${bin}" || { fail "${bin} not available"; return 1; }
    return 0
}

# ---------------------------------------------------------------- tmux
init_tmux() {
    mux_common_ensure tmux tmux || return 1
    local sess="${SHELL_MUX_SESSION:-shell-eggs}"
    tmux kill-server 2>/dev/null || true
    tmux new-session -d -s "${sess}" -n main 2>/dev/null || true
    if tmux has-session -t "${sess}" 2>/dev/null; then
        ok "tmux session '${sess}' detached and persistent"
        SHELL_DESC_EXTRA["tmux"]="tmux attach -t ${sess}  (or set DEFAULT_SHELL_MUX=tmux to drop SSH users inside)"
        return 0
    fi
    fail "tmux session could not be created"
    return 1
}

# ---------------------------------------------------------------- screen
init_screen() {
    mux_common_ensure screen screen || return 1
    local sess="${SHELL_MUX_SESSION:-shell-eggs}"
    screen -dmS "${sess}" /bin/bash 2>/dev/null || true
    if screen -ls 2>/dev/null | grep -q "\.${sess}"; then
        ok "screen session '${sess}' detached and persistent"
        SHELL_DESC_EXTRA["screen"]="screen -r ${sess}  (or set DEFAULT_SHELL_MUX=screen)"
        return 0
    fi
    fail "screen session could not be created"
    return 1
}

# ---------------------------------------------------------------- zellij
init_zellij() {
    mux_common_ensure zellij zellij || return 1
    local sess="${SHELL_MUX_SESSION:-shell-eggs}"
    zellij kill-all-sessions --yes >/dev/null 2>&1 || true
    zellij --session "${sess}" --background 2>/dev/null || zellij setup --check >/dev/null 2>&1 || true
    if zellij list-sessions 2>/dev/null | grep -q "${sess}"; then
        ok "zellij session '${sess}' detached and persistent"
        SHELL_DESC_EXTRA["zellij"]="zellij attach ${sess}"
        return 0
    fi
    warn "zellij session not confirmed (check zellij list-sessions)"
    return 0
}
