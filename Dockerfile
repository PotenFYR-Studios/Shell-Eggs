# ============================================================================
#  PotenFYR Studios - Multi-Shell Universal Egg :: Dockerfile
#  ghcr.io/potenfyr-studios/shell-eggs:latest
#  Base image carries ALL shell daemons + reverse-shell interpreters baked in
#  (matches the Database-Eggs "everything in the image, launcher verifies"
#  architecture). amd64 + arm64 via docker buildx in CI.
# ============================================================================
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \
        bash ca-certificates curl wget unzip xz-utils tar gzip procps psmisc \
        net-tools iproute2 iputils-ping dnsutils netcat-openbsd ncat socat \
        nmap openssl openssh-server openssh-sftp-server openssh-client \
        dropbear telnetd inetutils-telnetd busybox mosh tmux screen \
        python3 python3-pip perl ruby php-cli php-sqlite3 lua5.4 \
        golang-go locales supervisor util-linux login libpam-modules \
        git jq nano vim-tiny less file bsdextrautils sshpass \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd /home/container

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV TERM=xterm-256color

# Zellij: static binary from GitHub (not in Ubuntu 24.04 repos)
RUN ZJ_VER=0.40.1 \
    && case "$(dpkg --print-architecture)" in \
        amd64) ZJ_ARCH=x86_64 ;; \
        arm64) ZJ_ARCH=aarch64 ;; \
        *) ZJ_ARCH="" ;; \
    esac \
    && if [ -n "$ZJ_ARCH" ]; then \
        curl -fsSL "https://github.com/zellij-org/zellij/releases/download/v${ZJ_VER}/zellij-${ZJ_ARCH}-unknown-linux-musl.tar.gz" -o /tmp/zj.tgz \
        && tar -xzf /tmp/zj.tgz -C /usr/local/bin \
        && rm -f /tmp/zj.tgz; \
    fi || echo "[build] zellij optional, skipped"

# PowerShell via its repo (glibc static fallback below if this fails on arm)
RUN arch=$(dpkg --print-architecture) \
    && case "$arch" in \
        amd64) PS_ARCH=x64 ;; \
        arm64) PS_ARCH=arm64 ;; \
        *) PS_ARCH="" ;; \
    esac \
    && if [ -n "$PS_ARCH" ]; then \
        curl -fsSL "https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/powershell-7.4.6-linux-${PS_ARCH}.tar.gz" \
          -o /tmp/pwsh.tgz \
        && mkdir -p /opt/pwsh \
        && tar -xzf /tmp/pwsh.tgz -C /opt/pwsh \
        && ln -sf /opt/pwsh/pwsh /usr/local/bin/pwsh \
        && rm -f /tmp/pwsh.tgz; \
    fi || echo "[build] powershell optional, skipped"

# Runtime layout: panel mounts the server volume at /home/container
WORKDIR /home/container
COPY entrypoint.sh run.sh /usr/local/bin/
COPY scripts/ /usr/local/bin/scripts/
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/run.sh /usr/local/bin/scripts/*.sh \
    && ln -sf /usr/local/bin/entrypoint.sh /entrypoint.sh \
    && ln -sf /usr/local/bin/run.sh /usr/local/bin/scripts/../run.sh 2>/dev/null || true

# Unprivileged-friendly defaults; panels run this as root anyway.
RUN useradd -m -s /bin/bash container 2>/dev/null || true

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
