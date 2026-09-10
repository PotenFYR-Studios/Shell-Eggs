<!-- markdownlint-disable -->

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:22d3ee,50:a78bfa,100:f472b6&height=220&section=header&text=Shell%20Eggs&fontSize=52&fontColor=ffffff&fontAlignY=34&desc=One%20Egg.%20Every%20Shell.%20Every%20Direction.&descSize=18&descAlignY=55&animation=twinkling" width="100%" alt="Shell Eggs Banner"/>

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code:wght@600&size=19&pause=1200&color=22D3EE&center=true&vCenter=true&width=820&lines=SSH+with+real+CA+Certificates+and+Hardened+Keys-Only;Bash+Python+PHP+Perl+Ruby+Lua+Node+Go+Java+Reverse+Shells;TLS+and+Covert+Channels+-+Websocket+DNS+ICMP;Bind+Shells+Web+Terminals+and+Debug+Harnesses;Interactive+Paginated+Picker+with+SHELL_TYPE%3Dauto)](https://github.com/PotenFYR-Studios/Shell-Eggs)

<p align="center">
  <a href="https://potenfyr-studios.github.io/Shell-Eggs/"><img src="https://img.shields.io/badge/Website-Live%20Demo-22d3ee?style=for-the-badge&logo=googlechrome&logoColor=white&labelColor=1c1e26" alt="Website"/></a>
  <a href="https://discord.com/invite/zUaN2FPBec"><img src="https://img.shields.io/badge/Discord-Join%20us-5865F2?style=for-the-badge&logo=discord&logoColor=white&labelColor=1c1e26" alt="Discord"/></a>
  <a href="https://github.com/PotenFYR-Studios/Shell-Eggs/blob/main/SHELLs.md"><img src="https://img.shields.io/badge/Reference-SHELLs.md-f472b6?style=for-the-badge&logo=bookstack&logoColor=white&labelColor=1c1e26" alt="SHELLs.md"/></a>
  <img src="https://komarev.com/ghpvc/?username=PotenFYR-Studios-Shell-Eggs&color=a78bfa&style=for-the-badge&label=VIEWS&labelColor=1c1e26" alt="Views"/>
</p>

[![Shell Boot Tests](https://github.com/PotenFYR-Studios/Shell-Eggs/actions/workflows/test-docker.yml/badge.svg)](https://github.com/PotenFYR-Studios/Shell-Eggs/actions/workflows/test-docker.yml)
[![Build Universal Image](https://github.com/PotenFYR-Studios/Shell-Eggs/actions/workflows/docker-image.yml/badge.svg)](https://github.com/PotenFYR-Studios/Shell-Eggs/actions/workflows/docker-image.yml)
[![Validate Eggs & Scripts](https://github.com/PotenFYR-Studios/Shell-Eggs/actions/workflows/validate-eggs.yml/badge.svg)](https://github.com/PotenFYR-Studios/Shell-Eggs/actions/workflows/validate-eggs.yml)
[![Shells](https://img.shields.io/badge/Shells-54%20Types-22d3ee?style=flat-square&logo=gnu-bash)](https://github.com/PotenFYR-Studios/Shell-Eggs/blob/main/SHELLs.md)
[![Panels](https://img.shields.io/badge/Panels-Pterodactyl%20%7C%20Pelican%20%7C%20Feather%20%7C%20Wisp%20%7C%20Docker-9cf?style=flat-square)](#-supported-panels)
[![Docker Image](https://img.shields.io/badge/Docker%20Image-GHCR-blue?style=flat-square&logo=docker)](https://github.com/PotenFYR-Studios/Shell-Eggs/pkgs/container/shell-eggs)
[![License: Apache-2.0 + Commons Clause](https://img.shields.io/badge/License-Apache--2.0%20%2B%20Commons%20Clause-blue.svg?style=flat-square)](LICENSE)

<p align="center">
  <b>Host any shell - incoming, tunneled, reversed, encrypted, covert, web or debug - from one panel egg.</b><br>
  Credentials are the only mandatory input. Everything else is optional. Multiple shells run side by side
  on multiple panel ports, each printing its own connection guide to your console.
</p>

</div>

---

## Table of Contents

- [Why](#-why)
- [The Catalog](#-the-catalog--54-shells-across-7-directions)
- [Quick Start](#-quick-start)
- [Port Policy (panels + Docker)](#-port-policy-panels--docker)
- [Credentials](#-credentials-mandatory-everything-else-optional)
- [Secure + Certified Shells](#%EF%B8%8F-secure--certified-shells)
- [Reverse Shells](#-reverse-shells-every-direction)
- [Web + Browser Shells](#-web--browser-shells)
- [Debug Shells](#%EF%B8%8F-debug-shells)
- [SHELLs.md Reference](#-shell-smd-the-full-reference)
- [Supported Panels](#-supported-panels)
- [Startup Variables](#-startup-variables)
- [Website](#-website-vite--react--ts--bun)
- [Testing](#-testing--what-is-actually-verified)
- [Security & Legal](#%EF%B8%8F-security--legal)
- [License](#-license)

---

## 🤔 Why

Every panel ecosystem has *database* eggs, *game* eggs, *proxy* eggs - but shells are scattered across dozens of
half-maintained single-purpose eggs. **Shell-Eggs** is one egg that hosts **every shell type**:

- a hardened **OpenSSH** server (or **CA-certificate** auth, or tiny **Dropbear**, or classic **Telnet**),
- **tunnels** (`-L`, `-R`, `-D` SOCKS, X11, rsync, sshfs),
- **20+ reverse shells** (bash, python, PHP, perl, ruby, lua, node, powershell, go, java, groovy, awk, netcat family),
- **secure & covert channels** (TLS, websocket, DNS, ICMP),
- **bind shells** (plain + TLS), **web terminals** (ttyd, gotty) and **debug harnesses** (sshd -ddd, strace, tcpdump),
- all simultaneously, each on its own panel port, each printing its own how-to-connect guide.

<div align="center"><img src="https://capsule-render.vercel.app/api?type=rect&color=0:22d3ee,100:a78bfa&height=2" width="100%"/></div>

## 📚 The Catalog - 54 shells across 7 directions

| Category | Count | Highlights |
|---|---:|---|
| 🖥️ Server / incoming | 6 | `ssh` `ssh-cert` `ssh-hardened` `dropbear` `telnetd` `mosh-server` |
| 🔁 Multiplexers | 3 | `tmux` `screen` `zellij` |
| 🕳️ Tunnels | 6 | `ssh-local` `ssh-remote` `ssh-dynamic` `ssh-x11` `rsync-ssh` `sshfs` |
| 🎣 Reverse (plain) | 23 | `bash-tcp` `python-pty` `php-pentest` `node` `powershell` `golang` `java` `awk` `nc` `socat` ... |
| 🛡️ Secure / covert | 6 | `openssl-rs` `socat-tls` `ncat-ssl` `wssh` `dnscat` `icmp-shell` |
| 📡 Bind shells | 5 | `nc-bind` `socat-bind` `openssl-bind` `php-bind` `python-bind` |
| 🌐 Web terminals | 4 | `ttyd` `gotty` `php-webshell` `node-webshell` |
| 🔬 Debug | 4 | `ssh-debug` `strace-shell` `tcpdump-shell` `socat-probe` |

> Full connection examples + component explanations for **every** entry:
> **[SHELLs.md](SHELLs.md)** - also printed to your server console at boot.

<div align="center"><img src="https://capsule-render.vercel.app/api?type=rect&color=0:22d3ee,100:a78bfa&height=2" width="100%"/></div>

## 🚀 Quick Start

### Pterodactyl / Pelican / Feather / Wisp

1. Import [`egg-shell-multi.json`](egg-shell-multi.json) into your nest (or point the egg at the `update_url`).
2. Select the image `ghcr.io/potenfyr-studios/shell-eggs:latest`.
3. Allocate the primary port - that is all the egg needs. Extra shells get extra panel ports via `SHELL_EXTRA_PORTS`.
4. Set **Shell Usernames** (e.g. `alice,bob`). Leave **Shell User Passwords** as `auto` and secrets are generated for you.
5. Start. `SHELL_TYPE=auto` opens the interactive paginated picker in the console; pick any shell with your keyboard.

### Docker / standalone

```bash
docker run -d --name my-shells \
  -p 2222:2222 \
  -e SHELL_TYPE=ssh,tmux \
  -e SHELL_USERS=alice,bob \
  -e SHELL_PASSWORDS=auto,auto \
  ghcr.io/potenfyr-studios/shell-eggs:latest
```

### Interactive picker (AUTO mode)

`SHELL_TYPE=auto` (the default) turns the console into a full-screen paginated browser of the catalog:
categories -> shells -> port confirm -> done. It writes your choice and boots into it.

```
  +==========================================================+
  |  SHELL-EGGS INTERACTIVE PICKER - choose your shell        |
  +==========================================================+

  How do you want to reach this container?
   1) Server / incoming   - SSH, Dropbear, Telnet, Mosh
   2) Multiplexer         - tmux / screen / zellij
   3) Reverse shell       - container calls back to you
   4) Browse everything   - page through the full catalog
```

<div align="center"><img src="https://capsule-render.vercel.app/api?type=rect&color=0:22d3ee,100:a78bfa&height=2" width="100%"/></div>

## 📶 Port Policy (panels + Docker)

| Environment | Primary shell binds | Extra ported shells |
|---|---|---|
| Pterodactyl / Pelican / Feather / Wisp | the **panel-allocated** port (`SERVER_PORT`) | `SHELL_EXTRA_PORTS` positionally |
| Docker / standalone | `SERVER_PORT` (default 8888) | `SHELL_EXTRA_PORTS`, then `+10` steps |

- The **first ported shell always takes the primary container port** - allocate one port and SSH works.
- Reverse shells and multiplexers need **no** inbound port at all.
- Every printed port must be allocated in the panel firewall (or `docker run -p`) - the console guide reminds you per shell.

## 🔑 Credentials (mandatory; everything else optional)

- Set `SHELL_USERS=alice,bob` - the **only input the egg really needs**.
- `SHELL_PASSWORDS=auto,auto` (default) generates cryptographically random secrets:
  - printed once on the console,
  - persisted in `.env` and `.sh-users/credentials` (mode 600),
  - never rotated behind your back on restarts.
- Everything else - TLS, certs, tokens, MOTD, multiplexer names - has working defaults or is simply optional.

## 🛡️ Secure & Certified Shells

| Profile | Auth | Crypto | Highlights |
|---|---|---|---|
| `ssh` | password + key | modern defaults | SFTP, persistent host keys, per-user OS accounts |
| `ssh-cert` | **CA certificates** | ed25519 CA | container-local CA signs user + host certs; principals enforced; clients pin `@cert-authority` |
| `ssh-hardened` | **keys only** | chacha20 / aes-gcm only | passwords impossible (`AuthenticationMethods publickey`), `MaxAuthTries 2`, forwarding disabled |
| `openssl-bind` / `socat-tls` / `ncat-ssl` | TLS certs | auto-generated self-signed pair (or bring your own into `certs/`) | pin by fingerprint |

CI proves security properties, not just uptime: cert login succeeds, a cert for `carol` **cannot** log in as
`mallory`; the hardened profile rejects passwords and accepts keys.

## 🎣 Reverse Shells - every direction

Your listener first (`nc -lvnp 4444`), then pick any vehicle:

| Family | Vehicles |
|---|---|
| Shell devices | `bash-tcp`, `bash-udp` |
| Interpreters | `python`, `python-pty`, `php`, `php-pentest`, `perl`, `ruby`, `lua`, `node`, `powershell` |
| Compiled | `golang` (built at boot), `java` |
| One-liners | `groovy`, `awk` (gawk `/inet/tcp`) |
| Netcat family | `nc` (FIFO - openbsd + traditional), `nc-udp`, `ncat`, `socat` (full PTY), `cryptcat` |
| Secure | `openssl-rs`, `socat-tls`, `ncat-ssl` |
| Covert | `wssh` (websocket), `dnscat` (DNS TXT channel), `icmp-shell` (ping payloads) |

Every payload **reconnects forever** and is watched by the supervisor. Each boot prints:
`connects out to <host>:<port> (listener: nc -lvnp <port>)`.

## 🌐 Web & Browser Shells

- `ttyd` / `gotty` - full xterm.js terminal in the browser; basic-auth defaults to your first generated user.
- `php-webshell` / `node-webshell` - `curl "http://host:port/?token=...&cmd=id"`; token auth is mandatory (401 otherwise) and shown once at boot.

## 🩺 Debug Shells

`ssh-debug` (sshd `-ddd` + client `-vvv` recipe), `strace-shell` (every syscall traced to `logs/`),
`tcpdump-shell` (continuous pcap capture), `socat-probe` (hex-dump relay for protocol debugging).

## 📖 SHELLs.md - the full reference

**[SHELLs.md](SHELLs.md)** is the complete manual: per shell - what it is, when to use it, exact external
connection commands, and the key components explained. The website renders the same catalog, and every console
boot prints the relevant guide next to the shell you chose.

## 🧩 Supported Panels

| Panel | Status | Notes |
|---|---|---|
| Pterodactyl 1.x | ✅ | import the egg JSON, enable `pid_limit` feature |
| Pelican Panel | ✅ | same egg, panel-allocated port auto-detected |
| Feather Panel | ✅ | detected via `P_SERVER_UUID_SHORT`; TTY stop watcher included |
| Wisp | ✅ | universal entrypoint + port shims |
| Plain Docker | ✅ | `docker run` snippet above; no panel needed |
| Standalone Linux | ✅ | clone + `bash entrypoint.sh` (root recommended for SSH/Telnet profiles) |

## ⚙️ Startup Variables

<details open>
<summary><b>Click to expand</b> - full table also on <a href="https://potenfyr-studios.github.io/Shell-Eggs/">the website</a></summary>

| Variable | Default | Purpose |
|---|---|---|
| `SHELL_TYPE` | `auto` | shell id, comma list, or the interactive picker |
| `SHELL_USERS` | - | **mandatory in practice** - login users |
| `SHELL_PASSWORDS` | `auto` | positional; `auto` = generate crypto-random |
| `SHELL_EXTRA_TYPES` | - | additional shells beyond the primary |
| `SHELL_EXTRA_PORTS` | - | positional ports for extra ported shells |
| `SHELL_REVERSE_HOST/PORT` | - / 4444 | reverse callback target |
| `SHELL_SSH_PUBKEY_RAW` | - | seed `authorized_keys` (hardened needs this or panel file upload) |
| `SHELL_WEB_USER/PASS/TOKEN` | generated | web shell auth |
| `SHELL_MUX_SESSION`, `DEFAULT_SHELL_MUX` | `shell-eggs`, - | multiplexer wiring |
| `AUTO_GENERATE_CREDENTIALS` | 1 | secrets engine |
| `PANEL_STOP_WATCHER` | auto | TTY stop handling for Feather & co |
| `CLI_THEME`, `CLI_BANNER_GRADIENT` | `sh`, `auto` | console cosmetics |

</details>

## 🖥️ Website (Vite + React + TS + Bun)

The catalog lives at **[potenfyr-studios.github.io/Shell-Eggs](https://potenfyr-studios.github.io/Shell-Eggs/)** -
a Vite + React + TypeScript site built with **Bun**, featuring Magic-UI-style aurora backgrounds, border-beam
cards, typewriter + boot-terminal animations and number tickers. A build-time sync script pulls
`scripts/shell-registry.sh` + `egg-shell-multi.json` into typed data modules, so the site **auto-updates from the
repo** on every push (GitHub Actions -> GitHub Pages).

## 🧪 Testing - what is actually verified

CI boots the real image and proves real behavior (no mocks):

- ✅ SSH password login + SFTP + generated credentials (`sshpass` round-trip)
- ✅ SSH CA certificates: signed cert login works; **wrong principal rejected**
- ✅ Hardened keys-only: password **refused**, pubkey accepted
- ✅ Telnet: RFC854 server, shadow auth (SHA-512), login OK, bad password rejected
- ✅ Reverse shells (python/nc/bash): reach an external listener, command round-trip
- ✅ TLS bind shell: `socat OPENSSL` encrypted round-trip
- ✅ Registry coverage: all 54 ids have handlers; all 23 reverse payloads emit + syntax-check
- ✅ fd-3 panel stop, SIGTERM shutdown, credential persistence, panel-port binding

Run locally: `docker build -t shell-eggs:test . && bash tests/test-coverage.sh && bash tests/test-payloads.sh`

## ⚠️ Security & Legal

Shells are dual-use tools. Host them **only** on servers you own or are explicitly authorized to test.
Generated credentials, TLS certs and tokens are written mode-600 inside the container workspace. The hardened
and CA profiles exist precisely because defaults matter: keys-only, principal pinning, no root login.

## 📜 License

[Apache-2.0 + Commons Clause](LICENSE) - free to fork, modify, and use, and to build products or services around, but not to sell as a product - **Crafted with passion by [PotenFYR Studios](https://github.com/PotenFYR-Studios)**

_Support & Inquiries: [support@potenfyr.in](mailto:support@potenfyr.in)_

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:22d3ee,50:a78bfa,100:f472b6&height=120&section=footer&text=PotenFYR%20Studios&fontSize=22&fontColor=ffffff&fontAlignY=65" width="100%" alt="Footer"/>

</div>
