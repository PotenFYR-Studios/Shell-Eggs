<!-- markdownlint-disable -->

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:8b5cf6,50:ec4899,100:f97316&height=220&section=header&text=Shell-Eggs&fontSize=52&fontColor=ffffff&fontAlignY=34&animation=twinkling" width="100%" alt="Shell-Eggs banner"/>

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=20&pause=1200&color=8B5CF6&center=true&vCenter=true&width=800&lines=SSH+with+real+CA+Certificates+and+Hardened+Keys-Only;Bash+Python+PHP+Perl+Ruby+Lua+Node+Go+Java+Reverse+Shells;TLS+and+Covert+Channels+-+Websocket+DNS+ICMP;Bind+Shells+Web+Terminals+and+Debug+Harnesses)](https://github.com/PotenFYR-Studios/Shell-Eggs)

<p align="center">
  <a href="https://shell-eggs.docs.potenfyr.in/"><img src="https://img.shields.io/badge/Website-Docs-8b5cf6?style=for-the-badge&logo=googlechrome&logoColor=white&labelColor=1c1e26" alt="Website"/></a>
  <a href="https://discord.com/invite/zUaN2FPBec"><img src="https://img.shields.io/badge/Discord-Join%20us-5865F2?style=for-the-badge&logo=discord&logoColor=white&labelColor=1c1e26" alt="Discord"/></a>
  <a href="https://github.com/PotenFYR-Studios/Shell-Eggs"><img src="https://img.shields.io/badge/GitHub-Repository-181717?style=for-the-badge&logo=github&logoColor=white&labelColor=1c1e26" alt="GitHub"/></a>
  <a href="mailto:support@potenfyr.in"><img src="https://img.shields.io/badge/Email-support%40potenfyr.in-f97316?style=for-the-badge&logo=gmail&logoColor=white&labelColor=1c1e26" alt="Email"/></a>
  <a href="https://github.com/PotenFYR-Studios/Shell-Eggs"><img src="https://komarev.com/ghpvc/?username=PotenFYR-Studios-Shell-Eggs&color=ec4899&style=for-the-badge&label=PROFILE+VIEWS&labelColor=1c1e26" alt="Profile views"/></a>
</p>

[![Shell Boot Tests](https://img.shields.io/github/actions/workflow/status/PotenFYR-Studios/Shell-Eggs/test-docker.yml?style=flat-square&logo=githubactions&label=Shell%20Boot%20Tests&labelColor=1c1e26&color=2ea043)](https://github.com/PotenFYR-Studios/Shell-Eggs/actions/workflows/test-docker.yml)
[![Build Universal Image](https://img.shields.io/github/actions/workflow/status/PotenFYR-Studios/Shell-Eggs/docker-image.yml?style=flat-square&logo=githubactions&label=Build%20Universal%20Image&labelColor=1c1e26&color=2ea043)](https://github.com/PotenFYR-Studios/Shell-Eggs/actions/workflows/docker-image.yml)
[![Validate Eggs & Scripts](https://img.shields.io/github/actions/workflow/status/PotenFYR-Studios/Shell-Eggs/validate-eggs.yml?style=flat-square&logo=githubactions&label=Validate%20Eggs%20%26%20Scripts&labelColor=1c1e26&color=2ea043)](https://github.com/PotenFYR-Studios/Shell-Eggs/actions/workflows/validate-eggs.yml)
[![Shells](https://img.shields.io/badge/Shells-54%20Types-8b5cf6?style=flat-square&logo=gnu-bash&logoColor=white&labelColor=1c1e26)](https://github.com/PotenFYR-Studios/Shell-Eggs/blob/master/SHELLs.md)
[![Panels](https://img.shields.io/badge/Panels-Pterodactyl%20%7C%20Pelican%20%7C%20Feather%20%7C%20Wisp%20%7C%20Docker-8b5cf6?style=flat-square&labelColor=1c1e26)](#-supported-panels)
[![Docker Image](https://img.shields.io/badge/Docker%20Image-GHCR-2496ED?style=flat-square&logo=docker&logoColor=white&labelColor=1c1e26)](https://github.com/PotenFYR-Studios/Shell-Eggs/pkgs/container/shell-eggs)
[![License: Apache-2.0 + Commons Clause](https://img.shields.io/badge/License-Apache--2.0%20%2B%20Commons%20Clause-8b5cf6.svg?style=flat-square&logo=apache&logoColor=white&labelColor=1c1e26)](https://github.com/PotenFYR-Studios/Shell-Eggs/blob/master/LICENSE)

<p align="center">
  <b>Host any shell - incoming, tunneled, reversed, encrypted, covert, web or debug - from one panel egg.</b><br>
  Credentials are the only mandatory input. Everything else is optional. Multiple shells run side by side
  on multiple panel ports, each printing its own connection guide to your console.
</p>

</div>

---

## Table of Contents

- [Why](#-why)
- [The Catalog](#-the-catalog--54-shells-across-8-families)
- [Quick Start](#-quick-start)
- [Port Policy](#-port-policy-panels--docker)
- [Credentials](#-credentials-mandatory-everything-else-optional)
- [Secure & Certified Shells](#%EF%B8%8F-secure--certified-shells)
- [Reverse Shells](#-reverse-shells-every-direction)
- [Web & Browser Shells](#-web--browser-shells)
- [Debug Shells](#%EF%B8%8F-debug-shells)
- [Startup Variables](#-startup-variables)
- [Docs Website](#-docs-website-vite--react--ts--bun)
- [Testing](#-testing--what-is-actually-verified)
- [Contributing](#-contributing)
- [Security & Legal](#%EF%B8%8F-security--legal)
- [License](#-license)

---

## Why

Every panel ecosystem has *database* eggs, *game* eggs, *proxy* eggs - but shells are scattered across dozens of
half-maintained single-purpose eggs. **Shell-Eggs** is one egg that hosts **every shell type**:

- a hardened **OpenSSH** server (or **CA-certificate** auth, or tiny **Dropbear**, or classic **Telnet**),
- **tunnels** (`-L`, `-R`, `-D` SOCKS, X11, rsync, sshfs),
- **20+ reverse shells** (bash, python, PHP, perl, ruby, lua, node, powershell, go, java, groovy, awk, netcat family),
- **secure & covert channels** (TLS, websocket, DNS, ICMP),
- **bind shells** (plain + TLS), **web terminals** (ttyd, gotty) and **debug harnesses** (sshd -ddd, strace, tcpdump),
- all simultaneously, each on its own panel port, each printing its own how-to-connect guide.

<div align="center"><img src="https://capsule-render.vercel.app/api?type=rect&color=0:8b5cf6,100:ec4899&height=2" width="100%"/></div>

## The Catalog - 54 shells across 8 families

| Category | Count | Highlights |
|---|---:|---|
| Server / incoming | 6 | `ssh` `ssh-cert` `ssh-hardened` `dropbear` `telnetd` `mosh-server` |
| Multiplexers | 3 | `tmux` `screen` `zellij` |
| Tunnels | 6 | `ssh-local` `ssh-remote` `ssh-dynamic` `ssh-x11` `rsync-ssh` `sshfs` |
| Reverse (plain) | 23 | `bash-tcp` `python-pty` `php-pentest` `node` `powershell` `golang` `java` `awk` `nc` `socat` ... |
| Secure / covert | 6 | `openssl-rs` `socat-tls` `ncat-ssl` `wssh` `dnscat` `icmp-shell` |
| Bind shells | 5 | `nc-bind` `socat-bind` `openssl-bind` `php-bind` `python-bind` |
| Web terminals | 4 | `ttyd` `gotty` `php-webshell` `node-webshell` |
| Debug | 4 | `ssh-debug` `strace-shell` `tcpdump-shell` `socat-probe` |

> Full connection examples + component explanations for **every** entry:
> **[SHELLs.md](SHELLs.md)** - also printed to your server console at boot.

<div align="center"><img src="https://capsule-render.vercel.app/api?type=rect&color=0:8b5cf6,100:ec4899&height=2" width="100%"/></div>

## Quick Start

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

<div align="center"><img src="https://capsule-render.vercel.app/api?type=rect&color=0:8b5cf6,100:ec4899&height=2" width="100%"/></div>

## Port Policy (panels + Docker)

| Environment | Primary shell binds | Extra ported shells |
|---|---|---|
| Pterodactyl / Pelican / Feather / Wisp | the **panel-allocated** port (`SERVER_PORT`) | `SHELL_EXTRA_PORTS` positionally |
| Docker / standalone | `SERVER_PORT` (default 8888) | `SHELL_EXTRA_PORTS`, then `+10` steps |

- The **first ported shell always takes the primary container port** - allocate one port and SSH works.
- Reverse shells and multiplexers need **no** inbound port at all.
- Every printed port must be allocated in the panel firewall (or `docker run -p`) - the console guide reminds you per shell.

## Credentials (mandatory; everything else optional)

- Set `SHELL_USERS=alice,bob` - the **only input the egg really needs**.
- `SHELL_PASSWORDS=auto,auto` (default) generates cryptographically random secrets:
  - printed once on the console,
  - persisted in `.env` and `.sh-users/credentials` (mode 600),
  - never rotated behind your back on restarts.
- Everything else - TLS, certs, tokens, MOTD, multiplexer names - has working defaults or is simply optional.

## Secure & Certified Shells

| Profile | Auth | Crypto | Highlights |
|---|---|---|---|
| `ssh` | password + key | modern defaults | SFTP, persistent host keys, per-user OS accounts |
| `ssh-cert` | **CA certificates** | ed25519 CA | container-local CA signs user + host certs; principals enforced; clients pin `@cert-authority` |
| `ssh-hardened` | **keys only** | chacha20 / aes-gcm only | passwords impossible (`AuthenticationMethods publickey`), `MaxAuthTries 2`, forwarding disabled |
| `openssl-bind` / `socat-tls` / `ncat-ssl` | TLS certs | auto-generated self-signed pair (or bring your own into `certs/`) | pin by fingerprint |

CI proves security properties, not just uptime: cert login succeeds, a cert for `carol` **cannot** log in as
`mallory`; the hardened profile rejects passwords and accepts keys.

## Reverse Shells - every direction

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

## Web & Browser Shells

- `ttyd` / `gotty` - full xterm.js terminal in the browser; basic-auth defaults to your first generated user.
- `php-webshell` / `node-webshell` - `curl "http://host:port/?token=...&cmd=id"`; token auth is mandatory (401 otherwise) and shown once at boot.

## Debug Shells

`ssh-debug` (sshd `-ddd` + client `-vvv` recipe), `strace-shell` (every syscall traced to `logs/`),
`tcpdump-shell` (continuous pcap capture), `socat-probe` (hex-dump relay for protocol debugging).

## Startup Variables

<details open>
<summary><b>Click to expand</b> - full table also on <a href="https://shell-eggs.docs.potenfyr.in/docs/variables/">the docs site</a></summary>

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

## Docs Website (Vite + React + TS + Bun)

The catalog lives at **[shell-eggs.docs.potenfyr.in](https://shell-eggs.docs.potenfyr.in/)** -
a multi-page Vite + React + TypeScript site built with **Bun**, featuring the canonical PotenFYR design system,
gradient-text heroes, glass cards with border-beam effects, and per-route SEO meta + JSON-LD. A build-time sync
script pulls `scripts/shell-registry.sh` + `egg-shell-multi.json` into typed data modules, so the site
**auto-updates from the repo** on every push (GitHub Actions -> GitHub Pages).

## Testing - what is actually verified

CI boots the real image and proves real behavior (no mocks):

- SSH password login + SFTP + generated credentials (`sshpass` round-trip)
- SSH CA certificates: signed cert login works; **wrong principal rejected**
- Hardened keys-only: password **refused**, pubkey accepted
- Telnet: RFC854 server, shadow auth (SHA-512), login OK, bad password rejected
- Reverse shells (python/nc/bash): reach an external listener, command round-trip
- TLS bind shell: `socat OPENSSL` encrypted round-trip
- Registry coverage: all 54 ids have handlers; all 23 reverse payloads emit + syntax-check
- fd-3 panel stop, SIGTERM shutdown, credential persistence, panel-port binding

Run locally: `docker build -t shell-eggs:test . && bash tests/test-coverage.sh && bash tests/test-payloads.sh`

## Contributing

We welcome shell registry additions, bug fixes and docs improvements. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the full contribution flow:

- Edit `scripts/shell-registry.sh` to add a shell (id, name, category, port, root flag, description).
- Update `SHELLs.md` with the new entry's connection guide.
- Run `bash tests/test-coverage.sh` to verify the registry is consistent.
- The docs site auto-syncs from the registry on every build - no manual catalog.ts edits needed.

[![Issues](https://img.shields.io/badge/GitHub-Issues-8b5cf6?style=flat-square&logo=github&labelColor=1c1e26)](https://github.com/PotenFYR-Studios/Shell-Eggs/issues)

## Security & Legal

Shells are dual-use tools. Host them **only** on servers you own or are explicitly authorized to test.
Generated credentials, TLS certs and tokens are written mode-600 inside the container workspace. The hardened
and CA profiles exist precisely because defaults matter: keys-only, principal pinning, no root login.

For security-sensitive reports, mark the issue title with `[security]` or email
[support@potenfyr.in](mailto:support@potenfyr.in). See [SECURITY.md](SECURITY.md) for the full policy.

## License

Licensed under the **Apache License 2.0 with the Commons Clause** - free to fork, modify, use, self-host, and
redistribute for any purpose, including building products or services around it, but the software itself may
not be sold as a paid product. See the
[LICENSE](https://github.com/PotenFYR-Studios/Shell-Eggs/blob/master/LICENSE) file for details; **the LICENSE
file is authoritative** and summaries never override it. A plain-English breakdown lives on the docs site at
[shell-eggs.docs.potenfyr.in/license](https://shell-eggs.docs.potenfyr.in/license/).

---

Built by **[PotenFYR Studios](https://github.com/PotenFYR-Studios)** · [potenfyr.in](https://potenfyr.in) · Part of the **PotenFYR Studios** open-source ecosystem.

<!-- markdownlint-disable -->

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:f97316,50:ec4899,100:8b5cf6&height=120&section=footer&text=Made%20with%20%E2%9D%A4%EF%B8%8F%20by%20PotenFYR%20Studios&fontSize=22&fontColor=ffffff&animation=twinkling" width="100%" alt="footer"/>

</div>

<!-- markdownlint-enable -->
