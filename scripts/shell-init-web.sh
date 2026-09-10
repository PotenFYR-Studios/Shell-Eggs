#!/usr/bin/env bash
# ============================================================================
#  PotenFYR Studios - Multi-Shell Universal Egg :: scripts/shell-init-web.sh
#  Browser shells: ttyd / gotty web terminals and HTTP exec shells (PHP/Node).
#  All honor SHELL_BIND_PORT (panel port policy from run.sh).
# ============================================================================
# shellcheck source=shell-core.sh
[ -n "${SHELL_CORE_LOADED:-}" ] || source "${SCRIPTS_DIR}/shell-core.sh"

web_common() { # web_common <id> <guide>
    SHELL_DESC_EXTRA["${1}"]="${2}"
    return 0
}

# ---------------------------------------------------------------- ttyd
init_ttyd() {
    local port="${SHELL_BIND_PORT:-7681}"
    local bin=""
    if have ttyd; then bin="ttyd"
    else
        pkg_install ttyd 2>/dev/null || true
        have ttyd && bin="ttyd"
    fi
    if [ -z "${bin}" ]; then
        # static binary fallback
        local arch
        case "$(os_arch)" in
            amd64) arch="x86_64" ;;
            arm64) arch="aarch64" ;;
            *) arch="" ;;
        esac
        if [ -n "${arch}" ]; then
            local url="https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.${arch}"
            mkdir -p "${SERVER_DIR}/bin"
            if curl -fsSL --max-time 60 "${url}" -o "${SERVER_DIR}/bin/ttyd" 2>/dev/null \
               || wget -qT 60 "${url}" -O "${SERVER_DIR}/bin/ttyd" 2>/dev/null; then
                chmod +x "${SERVER_DIR}/bin/ttyd"
                bin="${SERVER_DIR}/bin/ttyd"
                export PATH="${SERVER_DIR}/bin:${PATH}"
            fi
        fi
    fi
    [ -n "${bin}" ] || { fail "ttyd unavailable (apt + static download failed)"; return 1; }
    ensure_os_users

    local auth_args=()
    if [ -n "${SHELL_WEB_USER:-}" ] && [ -n "${SHELL_WEB_PASS:-}" ]; then
        auth_args=(-c "${SHELL_WEB_USER}:${SHELL_WEB_PASS}")
    elif [ -n "${GENERATED_CREDENTIALS:-}" ]; then
        local first="${GENERATED_CREDENTIALS%% *}"
        auth_args=(-c "${first%%:*}:${first#*:}")
        warn "Web terminal protected with generated credential: ${first%%:*} (see .env)"
    fi

    log "Starting ttyd web terminal on port ${port}..."
    setsid "${bin}" -W -p "${port}" "${auth_args[@]}" bash -i >> "${SERVER_DIR}/logs/ttyd.log" 2>&1 < /dev/null &
    CHILD_PIDS["ttyd"]=$!
    ssh_ready_wait "${port}" && ok "ttyd ready on port ${port}"
    web_common "ttyd" "
CONNECT (browser):
  http://<container-host>:${port}          (allocate ${port} in the panel)
  https if you front it with a TLS reverse proxy - ttyd itself is plain ws
COMPONENTS:
  -W            writable (you can type) - without it the page is read-only
  -c user:pass  basic-auth gate; we default it to the first generated user
  bash -i       the program behind the terminal (swap for zsh/fish, etc.)"
    return 0
}

# ---------------------------------------------------------------- gotty
init_gotty() {
    local port="${SHELL_BIND_PORT:-8080}"
    local bin=""
    if have gotty; then bin="gotty"; fi
    if [ -z "${bin}" ]; then
        local arch
        case "$(os_arch)" in
            amd64) arch="amd64" ;;
            arm64) arch="arm64" ;;
            *) arch="" ;;
        esac
        if [ -n "${arch}" ]; then
            local url="https://github.com/sorenisanerd/gotty/releases/download/v1.5.0/gotty_v1.5.0_linux_${arch}.tar.gz"
            mkdir -p "${SERVER_DIR}/bin"
            if curl -fsSL --max-time 90 "${url}" -o /tmp/gotty.tgz 2>/dev/null \
               || wget -qT 90 "${url}" -O /tmp/gotty.tgz 2>/dev/null; then
                tar -xzf /tmp/gotty.tgz -C "${SERVER_DIR}/bin" gotty 2>/dev/null && chmod +x "${SERVER_DIR}/bin/gotty" && bin="${SERVER_DIR}/bin/gotty"
                export PATH="${SERVER_DIR}/bin:${PATH}"
            fi
            rm -f /tmp/gotty.tgz
        fi
    fi
    [ -n "${bin}" ] || { fail "gotty unavailable (static download failed)"; return 1; }
    ensure_os_users

    local auth_args=()
    if [ -n "${SHELL_WEB_USER:-}" ] && [ -n "${SHELL_WEB_PASS:-}" ]; then
        auth_args=(--credential "${SHELL_WEB_USER}:${SHELL_WEB_PASS}")
    fi

    log "Starting GoTTY web terminal on port ${port}..."
    setsid "${bin}" --port "${port}" --once=false "${auth_args[@]}" bash -i \
        >> "${SERVER_DIR}/logs/gotty.log" 2>&1 < /dev/null &
    CHILD_PIDS["gotty"]=$!
    ssh_ready_wait "${port}" && ok "GoTTY ready on port ${port}"
    web_common "gotty" "
CONNECT (browser):
  http://<container-host>:${port}
COMPONENTS:
  --credential user:pass   optional basic auth (set SHELL_WEB_USER/PASS)
  bash -i                  the attached program; single static binary server"
    return 0
}

# ---------------------------------------------------------------- php web shell
init_php_webshell() {
    local port="${SHELL_BIND_PORT:-8080}"
    pkg_install php-cli || true
    have php || { fail "php unavailable"; return 1; }
    local docroot="${SERVER_DIR}/www"
    mkdir -p "${docroot}"
    if [ ! -f "${docroot}/index.php" ] || [ -n "${SHELL_WEB_REGEN:-}" ]; then
        cat > "${docroot}/index.php" << 'PHPEOF'
<?php
// shell-eggs HTTP exec shell - AUTH REQUIRED (token below)
$token = getenv('SHELL_WEB_TOKEN') ?: '';
$given = $_POST['token'] ?? $_GET['token'] ?? '';
if ($token === '' || !hash_equals($token, $given)) {
    http_response_code(401);
    header('Content-Type: text/plain');
    echo "unauthorized: pass ?token=...\n";
    exit;
}
$cmd = $_POST['cmd'] ?? $_GET['cmd'] ?? '';
header('Content-Type: text/plain');
if ($cmd === '') { echo "usage: ?token=...&cmd=id\n"; exit; }
$out = shell_exec($cmd . ' 2>&1');
echo $out ?? '(no output)';
PHPEOF
    fi
    local token="${SHELL_WEB_TOKEN:-$(gen_rand 24)}"
    log "Starting PHP web shell on port ${port} (token auth)..."
    setsid env SHELL_WEB_TOKEN="${token}" php -S "0.0.0.0:${port}" -t "${docroot}" \
        >> "${SERVER_DIR}/logs/php-webshell.log" 2>&1 < /dev/null &
    CHILD_PIDS["php-webshell"]=$!
    ssh_ready_wait "${port}" && ok "PHP web shell ready on port ${port}"
    export SHELL_WEB_TOKEN_ACTIVE="${token}"
    web_common "php-webshell" "
CONNECT (from your machine):
  curl \"http://<host>:${port}/?token=${token}&cmd=id\"
  curl -d 'cmd=uname -a' \"http://<host>:${port}/?token=${token}\"
COMPONENTS:
  token         hash_equals-compared bearer in the URL - REQUIRED (401 otherwise)
  cmd           the shell command; output is plain text
  php -S        single-file server from the php-cli you already have"
    return 0
}

# ---------------------------------------------------------------- node web shell
init_node_webshell() {
    local port="${SHELL_BIND_PORT:-8080}"
    pkg_install nodejs npm 2>/dev/null || true
    have node || { fail "node unavailable"; return 1; }
    local out="${SERVER_DIR}/www/node-shell.js"
    mkdir -p "${SERVER_DIR}/www"
    cat > "${out}" << 'NODEEOF'
// shell-eggs node web shell - token auth required
const http = require('http');
const { exec } = require('child_process');
const token = process.env.SHELL_WEB_TOKEN || '';
const port = parseInt(process.env.PORT || '8080', 10);
http.createServer((req, res) => {
  const u = new URL(req.url, 'http://x');
  if (!token || u.searchParams.get('token') !== token) {
    res.writeHead(401); res.end('unauthorized\n'); return;
  }
  const cmd = u.searchParams.get('cmd') || '';
  if (!cmd) { res.writeHead(200); res.end('usage: ?token=..&cmd=id\n'); return; }
  exec(cmd, { timeout: 30000 }, (err, stdout, stderr) => {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end((stdout || '') + (stderr || '') + (err ? `error: ${err.message}\n` : ''));
  });
}).listen(port, '0.0.0.0', () => console.log(`node shell on ${port}`));
NODEEOF
    local token="${SHELL_WEB_TOKEN:-$(gen_rand 24)}"
    log "Starting Node web shell on port ${port} (token auth)..."
    setsid env SHELL_WEB_TOKEN="${token}" PORT="${port}" node "${out}" \
        >> "${SERVER_DIR}/logs/node-webshell.log" 2>&1 < /dev/null &
    CHILD_PIDS["node-webshell"]=$!
    ssh_ready_wait "${port}" && ok "Node web shell ready on port ${port}"
    export SHELL_WEB_TOKEN_ACTIVE="${token}"
    web_common "node-webshell" "
CONNECT (from your machine):
  curl \"http://<host>:${port}/?token=${token}&cmd=id\"
COMPONENTS:
  token         required bearer (401 without it); shown once here
  exec timeout  30s per command - keeps the event loop healthy"
    return 0
}
