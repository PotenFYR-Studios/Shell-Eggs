#!/usr/bin/env python3
"""Standalone listener used to validate the python reverse payload round-trip.
Writes received bytes to the file given as argv[1]; sends `id\\n` on connect."""
import socket
import sys
import time

out_path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/listener.out"
port = int(sys.argv[2]) if len(sys.argv) > 2 else 4464

srv = socket.socket()
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("0.0.0.0", port))
srv.listen(1)
srv.settimeout(12)
try:
    c, _ = srv.accept()
except Exception as exc:
    sys.stderr.write(f"NO_CONNECTION {exc}\n")
    sys.exit(1)
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
with open(out_path, "wb") as fh:
    fh.write(buf)
print(f"RECV_BYTES {len(buf)}")
