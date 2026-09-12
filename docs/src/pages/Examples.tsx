import { FadeIn } from "../components/magic";
import { Link } from "../router";
import { DocsShell } from "../components/DocsShell";
import { CHOOSERS, familyBySlug, REPO_TREE } from "../site";

export default function Examples({ route }: { route: string }) {
  return (
    <DocsShell
      route={route}
      crumbs={[{ label: "Docs", to: "/docs" }, { label: "Examples" }]}
    >
      <FadeIn>
        <p className="eyebrow">Shell-Eggs · Examples</p>
        <h1 className="grad-text mt-6 text-4xl font-extrabold tracking-tight">Which shell mode?</h1>
        <p className="mt-4 max-w-2xl" style={{ color: "var(--muted)" }}>
          Tell me what you want to do. Every card gives you the right <code>SHELL_TYPE</code> and the exact
          command to run on your side. The egg handles the rest.
        </p>
      </FadeIn>

      <FadeIn delay={0.08}>
        <div className="mt-10 grid gap-3.5 sm:grid-cols-2">
          {CHOOSERS.map((c) => {
            const fam = c.slug ? familyBySlug(c.slug) : undefined;
            return (
              <div key={c.want} className="doc-card">
                <div className="flex items-center gap-3">
                  <span className="text-2xl">{c.icon}</span>
                  <div>
                    <p className="text-[.92em] font-semibold text-white">{c.want}</p>
                    <p className="text-xs" style={{ color: "var(--faint)" }}>
                      {c.pick}
                    </p>
                  </div>
                </div>
                <pre className="mt-3" data-lang="cli">
                  <code>{c.then}</code>
                </pre>
                {fam && (
                  <Link to={`/docs/shells/${fam.slug}`} className="mt-2 inline-block text-xs font-semibold">
                    {fam.label} family →
                  </Link>
                )}
              </div>
            );
          })}
        </div>
      </FadeIn>

      <FadeIn delay={0.16}>
        <h2 className="doc-h2 mt-14">Listener recipes</h2>
        <p className="text-sm" style={{ color: "var(--muted)" }}>
          Before the egg's reverse/secure shells call you, your side must be listening. These are the gold-standard
          commands.
        </p>
        <div className="mt-4 grid gap-3.5 sm:grid-cols-2">
          {[
            { label: "Plain TCP listener", code: "nc -lvnp 4444" },
            { label: "Interactive PTY listener", code: "socat file:$(tty),raw,echo=0 TCP-L:4444" },
            { label: "TLS listener (openssl)", code: "openssl s_server -quiet -accept 4444 -cert server.pem -key server.pem" },
            { label: "TLS listener (socat)", code: "socat file:$(tty),raw,echo=0 OPENSSL-LISTEN:4444,cert=server.pem,verify=0" },
            { label: "UDP listener", code: "nc -luvnp 4444" },
            { label: "Generate a TLS pair first", code: "openssl req -x509 -newkey rsa:4096 -keyout key.pem -out server.pem -days 365 -nodes" },
          ].map((r) => (
            <div key={r.label} className="glass p-4">
              <p className="mono-label">{r.label}</p>
              <pre className="mt-2" data-lang="bash">
                <code>{r.code}</code>
              </pre>
            </div>
          ))}
        </div>
        <p className="mt-4 text-xs" style={{ color: "var(--faint)" }}>
          Every reverse-shell payload reconnects forever; the supervisor watches it. TLS listeners need a
          certificate pair (self-signed is fine for lab use - pin the fingerprint).
        </p>
      </FadeIn>

      <FadeIn delay={0.2}>
        <div className="glass mt-10 p-5">
          <p className="text-sm" style={{ color: "var(--muted)" }}>
            The complete reference with deep-dive explanations lives in{" "}
            <a href={`${REPO_TREE}/SHELLs.md`} target="_blank" rel="noopener">
              SHELLs.md
            </a>
            . Every boot prints the relevant guide next to the shell you chose.
          </p>
        </div>
      </FadeIn>
    </DocsShell>
  );
}
