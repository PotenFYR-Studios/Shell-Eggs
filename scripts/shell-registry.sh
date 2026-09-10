#!/usr/bin/env bash
# ============================================================================
#  PotenFYR Studios - Multi-Shell Universal Egg :: scripts/shell-registry.sh
#  Master catalog: every shell, tunnel, reverse, secure, bind, web and debug
#  shell the egg serves. 66 entries across 7 categories.
#  Format: register_shell <id> <display> <category> <default_port> <needs_root> <description>
#  NOTE: ids are referenced by scripts/shell-init-*.sh handlers, by
#        shell-picker.sh and documented in SHELLs.md; do not rename without
#        touching those files.
# ============================================================================

# ---- Server / incoming management shells (secure + classic) --------------- #
register_shell ssh             "OpenSSH Server"            server       22     1 "Hardened sshd: keys, passwords, SFTP, ciphers tuned"
register_shell ssh-cert        "OpenSSH CA Certificates"   server       22     1 "SSH user + host certificates signed by a container-local CA"
register_shell ssh-hardened    "OpenSSH Hardened"          server       22     1 "Keys-only, strong ciphers, no root login, blinding + rate limit"
register_shell dropbear        "Dropbear SSH"              server       22     1 "Tiny SSH for low-RAM containers (ECC + RSA keys)"
register_shell telnetd         "Telnet Server"             server       23     1 "Classic plaintext remote terminal (RFC854) - lab use"
register_shell mosh-server     "Mosh Server"               server       60000  0 "Roaming low-latency shell over UDP (survives IP changes)"
register_shell tmux            "Tmux Session"              multiplexer  0      0 "Persistent terminal multiplexer, attach/detach anywhere"
register_shell screen          "GNU Screen"                multiplexer  0      0 "Classic session multiplexer with hardstatus bar"
register_shell zellij          "Zellij Session"            multiplexer  0      0 "Modern multiplexer with layouts, panes and session resurrection"

# ---- SSH tunnels & forwarding --------------------------------------------- #
register_shell ssh-local       "SSH Local Tunnel (-L)"     tunnel       2222   0 "Forward a local port through this container (encrypted pipe)"
register_shell ssh-remote      "SSH Remote Tunnel (-R)"    tunnel       2222   0 "Expose this container's port on YOUR machine via sshd gatewaying"
register_shell ssh-dynamic     "SSH SOCKS Proxy (-D)"      tunnel       2222   0 "SOCKS5 proxy through the container - route any app through it"
register_shell ssh-x11         "SSH X11 Forwarding"        tunnel       2222   0 "Run remote GUI apps from the container on your X display"
register_shell rsync-ssh       "Rsync over SSH"            tunnel       22     0 "Fast delta file sync over the encrypted SSH channel"
register_shell sshfs           "SSHFS Filesystem"          tunnel       22     0 "Mount the container workspace as a local folder via SFTP"

# ---- Reverse shells - plain channel (TCP/UDP) ------------------------------ #
register_shell bash-tcp        "Bash /dev/tcp Reverse"     reverse      4444   0 "Pure bash reverse shell - zero external dependencies"
register_shell bash-udp        "Bash /dev/udp Reverse"     reverse      4444   0 "UDP flavor of the bash device reverse shell"
register_shell python          "Python Reverse Shell"      reverse      4444   0 "socket() + subprocess reverse shell (stable, reconnects)"
register_shell python-pty      "Python PTY Reverse"        reverse      4444   0 "Python reverse shell with full PTY (arrow keys, ctrl-c)"
register_shell php             "PHP fsockopen Reverse"     reverse      4444   0 "PHP proc_open reverse shell from any PHP runtime"
register_shell php-pentest     "PHP Pentestmonkey-style"   reverse      4444   0 "Classic full-featured PHP reverse shell script"
register_shell perl            "Perl Socket Reverse"       reverse      4444   0 "Core perl Socket module reverse shell"
register_shell ruby            "Ruby TCPSocket Reverse"    reverse      4444   0 "Ruby TCPSocket + system() reverse shell"
register_shell lua             "Lua Socket Reverse"        reverse      4444   0 "Lua io.popen loop reverse shell"
register_shell node            "Node.js net.Reverse"       reverse      4444   0 "Node.js child_process reverse shell"
register_shell powershell      "PowerShell TCP Reverse"    reverse      4444   0 ".NET TCPClient reverse shell for pwsh runtimes"
register_shell golang          "Golang Reverse Shell"      reverse      4444   0 "Go source, compiled on the fly into a static binary"
register_shell groovy          "Groovy Reverse Shell"      reverse      4444   0 "Groovy/Jenkins console reverse shell"
register_shell java            "Java Reverse Shell"        reverse      4444   0 "Plain Java socket reverse shell, compiled at boot"
register_shell awk             "Gawk Reverse Shell"        reverse      4444   0 "/inet/tcp gawk one-file reverse shell (surprising but real)"

# ---- Reverse shells - netcat family ---------------------------------------- #
register_shell nc              "Netcat Reverse"            reverse      4444   0 "Classic TCP reverse via FIFO relay (openbsd + traditional)"
register_shell nc-udp          "Netcat UDP Reverse"        reverse      4444   0 "UDP reverse shell (listener must speak first)"
register_shell ncat            "Ncat Reverse"              reverse      4444   0 "Nmap's netcat with --exec and reconnect"
register_shell socat           "Socat Reverse (pty)"       reverse      4444   0 "Fully interactive socat EXEC pty reverse shell"
register_shell cryptcat        "Cryptcat Reverse"          reverse      4444   0 "Netcat with twofish encryption (-k shared key)"

# ---- Secure/encrypted reverse shells (TLS first) --------------------------- #
register_shell openssl-rs      "OpenSSL TLS Reverse"       reverse      4444   0 "TLS-wrapped shell via s_client; pairs with socat OPENSSL-LISTEN"
register_shell socat-tls       "Socat TLS Reverse"         reverse      4444   0 "socat OPENSSL reverse shell with auto-generated client cert"
register_shell ncat-ssl        "Ncat SSL Reverse"          reverse      4444   0 "ncat --ssl reverse shell (nmap TLS stack)"
register_shell wssh            "Websocket Shell (wssh)"    secure-web   7681   0 "Python websocket shell client over ws:// (covert, 80/443-like)"
register_shell dnscat          "DNS Tunnel Shell"          secure-web   0      0 "C2-over-DNS client (dnscat2-style) for egress-restricted nets"
register_shell icmp-shell      "ICMP Shell"                secure-web   0      0 "Reverse shell inside ICMP echo payloads (icmpsh-style)"

# ---- Bind shells (attacker connects IN to the container) ------------------- #
register_shell nc-bind         "Netcat Bind Shell"         bind         5555   0 "nc -lp /bin/sh - classic bind shell on demand"
register_shell socat-bind      "Socat Bind Shell (pty)"    bind         5555   0 "Full PTY bind shell via socat TCP-LISTEN"
register_shell openssl-bind    "OpenSSL TLS Bind"          bind         5555   0 "TLS bind shell: socat OPENSSL-LISTEN + bash"
register_shell php-bind        "PHP Bind Shell"            bind         5555   0 "PHP socket_accept bind shell"
register_shell python-bind     "Python Bind Shell"         bind         5555   0 "Python socket bind + PTY shell"

# ---- Web/browser shells ---------------------------------------------------- #
register_shell ttyd            "ttyd Web Terminal"         web          7681   0 "Full xterm.js terminal in your browser (TLS optional)"
register_shell gotty           "GoTTY Web Terminal"        web          8080   0 "Go static binary web terminal - no install on client"
register_shell php-webshell    "PHP Web Shell (HTTP)"      web          8080   0 "POST cmd= PHP HTTP exec shell served by php -S"
register_shell node-webshell   "Node.js Web Shell"         web          8080   0 "Node http server exec shell - cmd= query or POST body"

# ---- Debugging / diagnostics shells ---------------------------------------- #
register_shell ssh-debug       "SSH Debug Session"         debug        2222   0 "Foreground sshd -ddd + client -vvv recipe for auth issues"
register_shell strace-shell    "Strace Session Shell"      debug        0      0 "Login shell wrapper that straces every syscall to file"
register_shell tcpdump-shell   "Tcpdump Capture Shell"     debug        0      0 "Bind a shell that also captures traffic to pcap for review"
register_shell socat-probe     "Socat Probe Relay"         debug        9000   0 "Raw TCP relay + hex dump for protocol debugging"
