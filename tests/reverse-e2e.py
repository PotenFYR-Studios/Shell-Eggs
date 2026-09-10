#!/usr/bin/env python3
"""Both-sides-in-one test: listener thread + payload subprocess, no races."""
import os
import socket
import subprocess
import threading
import time

received = {}


def listener() -> None:
    srv = socket.socket()
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("127.0.0.1", 4471))
    srv.listen(1)
    srv.settimeout(12)
    try:
        c, _ = srv.accept()
    except Exception as exc:
        received["error"] = str(exc)
        return
    time.sleep(1)
    c.sendall(b"id\n")
    c.settimeout(4)
    buf = b""
    try:
        while True:
            d = c.recv(4096)
            if not d:
                break
            buf += d
    except Exception:
        pass
    received["data"] = buf


t = threading.Thread(target=listener, daemon=True)
t.start()
time.sleep(0.5)

env = os.environ.copy()
env["SHELL_REVERSE_HOST"] = "127.0.0.1"
env["SHELL_REVERSE_PORT"] = "4471"
try:
    p = subprocess.run(
        ["python3", "/home/container/payloads/python.run"],
        env=env, capture_output=True, timeout=8,
    )
    print("PAYLOAD_STDERR:", p.stderr.decode()[:200])
except subprocess.TimeoutExpired:
    print("payload ran until timeout (expected: infinite loop)")

t.join(timeout=6)
data = received.get("data", b"")
if "error" in received:
    print("LISTENER_ERROR:", received["error"])
print("RECV:", data.decode(errors="replace")[:200])
print("TALKS" if b"uid=" in data else "SILENT")
