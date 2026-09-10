#!/usr/bin/env python3
"""Telnet login check used by CI (scripts/telnet-check.py target)."""
import socket
import time

s = socket.create_connection(("127.0.0.1", 2323), timeout=5)
time.sleep(0.8)
for payload in (b"carol\n", b"carolpass\n", b"id && echo TELNET_MARKER_OK\n"):
    s.send(payload)
    time.sleep(0.8)
s.settimeout(2)
data = b""
try:
    while True:
        chunk = s.recv(8192)
        if not chunk:
            break
        data += chunk
except socket.timeout:
    pass
assert b"TELNET_MARKER_OK" in data, data[-200:]
print("TELNET_OK")
