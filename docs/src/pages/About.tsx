import { FadeIn } from "../components/magic";
import { Link } from "../router";
import { REPO, REPO_TREE } from "../site";

export default function About() {
  return (
    <main className="mx-auto max-w-4xl px-6 pt-20 pb-24">
      <FadeIn>
        <p className="eyebrow">Shell-Eggs · About</p>
        <h1 className="grad-text mt-6 text-4xl font-extrabold tracking-tight">About the egg</h1>
        <p className="mt-4 max-w-2xl" style={{ color: "var(--muted)" }}>
          Shell-Eggs is one Pterodactyl panel egg that hosts every shell direction (incoming, tunneled, reversed,
          encrypted, covert, web and debug) from a single Docker image. Built by{" "}
          <a href="https://github.com/PotenFYR-Studios" target="_blank" rel="noopener">
            PotenFYR Studios
          </a>
          .
        </p>
      </FadeIn>

      <h2 className="doc-h2">Supported panels</h2>
      <FadeIn>
        <table className="data-table">
          <thead>
            <tr>
              <th>Platform</th>
              <th>Status</th>
              <th>Notes</th>
            </tr>
          </thead>
          <tbody>
            {[
              ["Pterodactyl 1.x", "✅", "import the egg JSON, enable pid_limit feature"],
              ["Pelican Panel", "✅", "same egg, panel-allocated port auto-detected"],
              ["Feather Panel", "✅", "detected via P_SERVER_UUID_SHORT; TTY stop watcher included"],
              ["Wisp", "✅", "universal entrypoint + port shims"],
              ["Plain Docker", "✅", "docker run; no panel needed"],
              ["Standalone Linux", "✅", "clone + bash entrypoint.sh (root recommended for SSH/Telnet)"],
            ].map(([p, s, n]) => (
              <tr key={p}>
                <td>{p}</td>
                <td className="whitespace-nowrap">{s}</td>
                <td className="text-sm" style={{ color: "var(--muted)" }}>
                  {n}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </FadeIn>

      <h2 className="doc-h2">What CI actually verifies</h2>
      <FadeIn>
        <ul className="space-y-1 text-sm" style={{ color: "var(--text-2)" }}>
          <li>SSH password login + SFTP + generated credentials (sshpass round-trip)</li>
          <li>SSH CA certificates: signed cert login works; wrong principal rejected</li>
          <li>Hardened keys-only: password refused, pubkey accepted</li>
          <li>Telnet: RFC854 server, shadow auth (SHA-512), login OK, bad password rejected</li>
          <li>Reverse shells (python/nc/bash): reach an external listener, command round-trip</li>
          <li>TLS bind shell: socat OPENSSL encrypted round-trip</li>
          <li>Registry coverage: all 54 ids have handlers; all 23 reverse payloads emit + syntax-check</li>
          <li>fd-3 panel stop, SIGTERM shutdown, credential persistence, panel-port binding</li>
        </ul>
        <p className="mt-4 text-xs" style={{ color: "var(--faint)" }}>
          No mocks. CI boots the real image and proves real behavior on every push.{" "}
          <a href={`${REPO}/actions`} target="_blank" rel="noopener">
            GitHub Actions
          </a>
          .
        </p>
      </FadeIn>

      <h2 className="doc-h2">Security and legal</h2>
      <FadeIn>
        <p className="text-sm" style={{ color: "var(--muted)" }}>
          Shells are dual-use tools. Host them only on servers you own or are explicitly authorized to test.
          Generated credentials, TLS certs and tokens are written mode-600 inside the container workspace. The
          hardened and CA profiles exist precisely because defaults matter: keys-only, principal pinning, no root
          login.
        </p>
        <p className="mt-3 text-sm" style={{ color: "var(--muted)" }}>
          For security-sensitive reports, mark the issue title with <code>[security]</code> or email{" "}
          <a href="mailto:support@potenfyr.in">support@potenfyr.in</a>. Avoid posting exploit details until a fix
          lands.
        </p>
      </FadeIn>

      <h2 className="doc-h2">License</h2>
      <FadeIn>
        <p className="text-sm" style={{ color: "var(--muted)" }}>
          Licensed under the <strong>Apache License 2.0 with the Commons Clause</strong>. Free to fork, modify, use,
          and build products or services around it, but the software itself may not be sold as a paid product. See
          the{" "}
          <a href={`${REPO_TREE}/LICENSE`} target="_blank" rel="noopener">
            LICENSE
          </a>{" "}
          file for details; <strong>the LICENSE file is authoritative</strong> and summaries never override it. A
          plain-English breakdown lives on the{" "}
          <Link to="/license">license page</Link>.
        </p>
      </FadeIn>

      <h2 className="doc-h2">Contributing</h2>
      <FadeIn>
        <p className="text-sm" style={{ color: "var(--muted)" }}>
          We welcome shell registry additions, bug fixes and docs improvements. See{" "}
          <a href={`${REPO_TREE}/CONTRIBUTING.md`} target="_blank" rel="noopener">
            CONTRIBUTING.md
          </a>{" "}
          for the contribution flow (edit <code>scripts/shell-registry.sh</code> + <code>SHELLs.md</code>; the docs
          site auto-syncs on build). Issues welcome at{" "}
          <a href={`${REPO}/issues`} target="_blank" rel="noopener">
            GitHub Issues
          </a>
          .
        </p>
      </FadeIn>

      <FadeIn delay={0.12}>
        <div className="glass mt-12 p-6 text-center">
          <p className="text-sm" style={{ color: "var(--muted)" }}>
            Crafted with passion by{" "}
            <a href="https://github.com/PotenFYR-Studios" target="_blank" rel="noopener">
              PotenFYR Studios
            </a>{" "}
            ·{" "}
            <a href="https://potenfyr.in" target="_blank" rel="noopener">
              potenfyr.in
            </a>{" "}
            ·{" "}
            <a href="https://discord.com/invite/zUaN2FPBec" target="_blank" rel="noopener">
              Discord
            </a>{" "}
            ·{" "}
            <a href={`${REPO}/issues`} target="_blank" rel="noopener">
              Issues
            </a>
          </p>
          <p className="mt-2 text-xs" style={{ color: "var(--faint)" }}>
            Support: <a href="mailto:support@potenfyr.in">support@potenfyr.in</a>
          </p>
        </div>
      </FadeIn>
    </main>
  );
}
