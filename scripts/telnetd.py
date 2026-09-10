#!/usr/bin/env python3
"""
PotenFYR Studios - Multi-Shell Universal Egg :: scripts/telnetd.py
Dependency-free RFC854-compliant-enough telnet server:
  - IAC option negotiation (refuses everything, strips escapes)
  - login/password auth against /etc/shadow (falls back to skip when not root)
  - PTY-backed bash session with our MOTD
Env: TELNET_PORT, SHELL_MOTD
"""
import os
import socket
import struct
import sys
import threading
import time
import select
import termios
import tty
import pty
import pwd

IAC, DONT, DO, WONT, WILL, SB, SE = 255, 254, 253, 252, 251, 250, 240

def negotiate(data: bytes) -> bytes:
    """Strip/answer telnet control sequences, return clean user input."""
    out = bytearray()
    i = 0
    n = len(data)
    while i < n:
        b = data[i]
        if b != IAC:
            out.append(b)
            i += 1
            continue
        if i + 1 >= n:
            break
        cmd = data[i + 1]
        if cmd in (DO, DONT, WILL, WONT):
            if i + 2 < n:
                # answer: we refuse everything
                if cmd == WILL:
                    out += bytes([IAC, DONT, data[i + 2]])
                elif cmd == DO:
                    out += bytes([IAC, WONT, data[i + 2]])
                i += 3
            else:
                i += 2
        elif cmd == SB:
            # subnegotiation: skip to IAC SE
            j = data.find(bytes([IAC, SE]), i)
            i = (j + 2) if j != -1 else n
        elif cmd == IAC:
            out.append(IAC)  # escaped 0xFF
            i += 2
        else:
            i += 2
    return bytes(out)

def _hash_for(username: str):
    try:
        import spwd  # python < 3.13
        return spwd.getspnam(username).sp_pwdp
    except Exception:
        pass
    try:
        with open("/etc/shadow", "r", encoding="utf-8") as fh:
            for line in fh:
                parts = line.rstrip("\n").split(":")
                if parts and parts[0] == username:
                    return parts[1]
    except Exception:
        pass
    return None

def _verify(password: str, phash: str) -> bool:
    # 1) stdlib crypt (python <= 3.12)
    try:
        import crypt as _crypt
        return _crypt.crypt(password, phash) == phash
    except Exception:
        pass
    # 2) openssl CLI fallback: schemes 1 (md5), 5 (sha256), 6 (sha512)
    parts = phash.split("$")
    if len(parts) >= 4 and parts[1] in ("1", "5", "6"):
        import subprocess
        scheme = {"1": "-1", "5": "-5", "6": "-6"}[parts[1]]
        salt = f"${parts[1]}${parts[2]}"
        try:
            out = subprocess.run(
                ["openssl", "passwd", scheme, "-salt", salt, password],
                capture_output=True, text=True, timeout=5,
            ).stdout.strip()
            return out == phash
        except Exception:
            return False
    return False

def check_password(username: str, password: str) -> bool:
    phash = _hash_for(username)
    if phash is None:
        return False
    if phash in ("", "!", "*", "!!", "!*"):
        return False  # locked / no password
    return _verify(password, phash)

def read_line(conn: socket.socket, prompt: str, echo: bool = True) -> str:
    conn.sendall(prompt.encode())
    buf = bytearray()
    while True:
        chunk = conn.recv(256)
        if not chunk:
            return ""
        clean = negotiate(chunk)
        for ch in clean:
            if ch in (0x0D, 0x0A):
                conn.sendall(b"\r\n")
                return buf.decode(errors="replace")
            elif ch in (0x7F, 0x08):  # backspace
                if buf:
                    buf.pop()
                    if echo:
                        conn.sendall(b"\b \b")
            elif 0x20 <= ch < 0x7F:
                buf.append(ch)
                if echo:
                    conn.sendall(bytes([ch]))

def session(conn: socket.socket, addr) -> None:
    try:
        motd = os.environ.get("SHELL_MOTD", "Welcome to the Multi-Shell Universal Egg (PotenFYR Studios).")
        conn.sendall(("\r\n" + motd + "\r\nAuthorized use only. All sessions may be logged.\r\n\r\n").encode())

        can_auth = os.getuid() == 0
        user = None
        for _attempt in range(3):
            name = read_line(conn, "login: ").strip()
            if not name:
                return
            if not can_auth:
                # unprivileged demo mode: accept any name, no password check
                user = name
                conn.sendall(b"(unprivileged mode: password check skipped)\r\n")
                break
            pw = read_line(conn, "Password: ", echo=False)
            if check_password(name, pw):
                user = name
                break
            conn.sendall(b"Login incorrect\r\n\r\n")
        if not user:
            return

        pwrec = pwd.getpwnam(user)
        conn.sendall(f"\r\nLast login: {time.ctime()}\r\n".encode())
        shell = pwrec.pw_shell or "/bin/bash"

        pid, fd = pty.fork()
        if pid == 0:
            # child: inside the PTY
            os.environ["HOME"] = pwrec.pw_dir
            os.environ["USER"] = user
            os.environ["LOGNAME"] = user
            os.environ["SHELL"] = shell
            os.environ["TERM"] = "xterm-256color"
            try:
                os.setgid(pwrec.pw_gid)
                os.setuid(pwrec.pw_uid)
            except PermissionError:
                pass
            os.chdir(pwrec.pw_dir or "/")
            os.execl(shell, os.path.basename(shell), "-i")
            os._exit(127)

        # parent: relay network <-> pty, translating CR
        try:
            while True:
                r, _, _ = select.select([conn, fd], [], [], 30)
                if conn in r:
                    data = conn.recv(4096)
                    if not data:
                        break
                    clean = negotiate(data)
                    clean = clean.replace(b"\r\n", b"\n").replace(b"\r\x00", b"\n").replace(b"\r", b"\n")
                    if clean:
                        os.write(fd, clean)
                if fd in r:
                    try:
                        data = os.read(fd, 4096)
                    except OSError:
                        break
                    if not data:
                        break
                    conn.sendall(data.replace(b"\n", b"\r\n"))
                if pid in r:
                    break
        finally:
            try:
                os.kill(pid, 9)
                os.waitpid(pid, 0)
            except Exception:
                pass
    except Exception:
        pass
    finally:
        try:
            conn.close()
        except Exception:
            pass

def main() -> None:
    port = int(os.environ.get("TELNET_PORT", "23"))
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("0.0.0.0", port))
    srv.listen(8)
    print(f"[telnetd.py] listening on 0.0.0.0:{port}", flush=True)
    while True:
        conn, addr = srv.accept()
        threading.Thread(target=session, args=(conn, addr), daemon=True).start()

if __name__ == "__main__":
    main()
