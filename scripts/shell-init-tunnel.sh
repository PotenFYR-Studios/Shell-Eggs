#!/usr/bin/env bash
# ============================================================================
#  PotenFYR Studios - Multi-Shell Universal Egg :: scripts/shell-init-tunnel.sh
#  SSH tunnel/forwarding handlers + hardened/cert SSH variants.
#  Every handler sets SHELL_DESC_EXTRA[id] to a how-to-connect guide with the
#  key components explained inline (also mirrored into SHELLs.md).
#  Port policy: handlers honor SHELL_BIND_PORT (exported by run.sh per shell,
#  = the panel-assigned port for the primary shell).
# ============================================================================
# shellcheck source=shell-core.sh
[ -n "${SHELL_CORE_LOADED:-}" ] || source "${SCRIPTS_DIR}/shell-core.sh"

tunnel_ensure_sshd() { # start sshd with an optional config snippet file
    local extra_cfg="$1" id="$2" guide="$3"
    local port="${SHELL_BIND_PORT:-2222}"
    local dir="${SERVER_DIR}/.ssh-host"
    mkdir -p "${dir}" /run/sshd 2>/dev/null || true
    chmod 0755 /run/sshd 2>/dev/null || true

    pkg_install openssh-server || true
    have sshd || { fail "sshd unavailable"; return 1; }
    ensure_os_users

    for kt in rsa ecdsa ed25519; do
        kf="${dir}/ssh_host_${kt}_key"
        [ -f "${kf}" ] || ssh-keygen -q -t "${kt}" -N '' -f "${kf}" >/dev/null 2>&1 || true
    done

    local cfg="${dir}/sshd_tunnel_config"
    {
        printf 'Port %s\nListenAddress 0.0.0.0\n' "${port}"
        printf 'HostKey %s/ssh_host_rsa_key\nHostKey %s/ssh_host_ecdsa_key\nHostKey %s/ssh_host_ed25519_key\n' "${dir}" "${dir}" "${dir}"
        printf 'PasswordAuthentication yes\nPermitRootLogin no\nUsePAM no\nSubsystem sftp internal-sftp\n'
        # tunneling permissions
        printf 'AllowTcpForwarding yes\nPermitTunnel yes\nX11Forwarding yes\nGatewayPorts yes\nPermitOpen any\n'
        cat "${extra_cfg}" 2>/dev/null || true
    } > "${cfg}"

    if ! /usr/sbin/sshd -f "${cfg}" -E "${SERVER_DIR}/logs/sshd-tunnel.log"; then
        fail "sshd (tunnel profile) failed to start"
        return 1
    fi
    ssh_ready_wait "${port}" || warn "sshd tunnel port not answering yet"
    ok "Tunnel sshd ready on port ${port}"
    SHELL_DESC_EXTRA["${id}"]="${guide}"
    return 0
}

# ---------------------------------------------------------------- -L local
init_ssh_local() {
    tunnel_ensure_sshd "" "ssh-local" \
"CONNECT (from your machine):
  ssh -p ${SHELL_BIND_PORT:-2222} -N -L 8080:target.host:80 <user>@<this-host>
COMPONENTS:
  -N            no shell, tunnel only
  -L 8080:...   local port 8080 forwards to target.host:80 FROM the container
  usage         open http://localhost:8080 - traffic exits at the container"
    return $?
}

# ---------------------------------------------------------------- -R remote
init_ssh_remote() {
    tunnel_ensure_sshd "" "ssh-remote" \
"CONNECT (from the container outward or any client):
  ssh -p ${SHELL_BIND_PORT:-2222} -N -R 9090:internal.host:80 <user>@<this-host>
COMPONENTS:
  -R 9090:...   connections to port 9090 ON THE CONTAINER go to internal.host:80
  GatewayPorts  enabled, so 0.0.0.0 binds work for multi-client exposure"
    return $?
}

# ---------------------------------------------------------------- -D socks
init_ssh_dynamic() {
    tunnel_ensure_sshd "" "ssh-dynamic" \
"CONNECT (from your machine):
  ssh -p ${SHELL_BIND_PORT:-2222} -N -D 1080 <user>@<this-host>
COMPONENTS:
  -D 1080       opens a SOCKS5 proxy on your localhost:1080
  usage         curl --socks5 127.0.0.1:1080 ... or set browser proxy
  exit IP       becomes the container's IP"
    return $?
}

# ---------------------------------------------------------------- X11
init_ssh_x11() {
    tunnel_ensure_sshd "X11DisplayOffset 10\nX11UseLocalhost yes" "ssh-x11" \
"CONNECT (from a machine running an X server):
  ssh -p ${SHELL_BIND_PORT:-2222} -X <user>@<this-host>
COMPONENTS:
  -X            forwards X11; -Y trusts it fully (faster, less safe)
  test          xeyes / xcalc after login - GUI renders on YOUR display"
    return $?
}

# ---------------------------------------------------------------- rsync
init_rsync_ssh() {
    pkg_install rsync openssh-server || true
    tunnel_ensure_sshd "" "rsync-ssh" \
"CONNECT (from your machine):
  rsync -avz -e 'ssh -p ${SHELL_BIND_PORT:-2222}' ./folder/ <user>@<this-host>:~/dest/
COMPONENTS:
  -a            archive mode (perms, times, symlinks)
  -z            compress in flight
  -e 'ssh -p'   transport through this encrypted sshd"
    return $?
}

# ---------------------------------------------------------------- sshfs
init_sshfs() {
    pkg_install openssh-sftp-server || true
    tunnel_ensure_sshd "" "sshfs" \
"CONNECT (from your machine):
  sshfs -p ${SHELL_BIND_PORT:-2222} <user>@<this-host>:/home/container ./mnt
COMPONENTS:
  sshfs         mounts the container FS over the SFTP protocol
  unmount       fusermount -u ./mnt (or: diskutil unmount on macOS)"
    return $?
}
