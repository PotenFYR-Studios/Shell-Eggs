import { AuroraBackdrop, BootTerminal, FadeIn, NumberTicker, ShimmerButton, useTypewriter } from "../components/magic";
import { Link } from "../router";
import { FAMILIES, REPO, REPO_TREE } from "../site";
import { CATEGORY_META, CATEGORY_COUNTS, TOTAL_SHELLS, EGG_VARIABLES } from "../data/catalog";

const REPO_SHELLS_MD = `${REPO_TREE}/SHELLs.md`;

function Hero() {
  const typed = useTypewriter([
    "ssh -p 2222 alice@my-server",
    "bash-interactive picker: choose any of the catalog shells",
    "python-pty reverse shell -> nc -lvnp 4444",
    "socat OPENSSL-LISTEN:5555 (TLS bind, certs auto-generated)",
    "curl ?token=...&cmd=id  (token-authed web shell)",
    "ssh-cert login: signed by the container-local CA",
  ]);
  return (
    <header className="relative mx-auto max-w-6xl px-6 pt-28 pb-16">
      <AuroraBackdrop />
      <FadeIn>
        <p className="eyebrow">
          <span className="inline-block h-2 w-2 rounded-full" style={{ background: "#34d399", boxShadow: "0 0 8px rgba(16,185,129,.5)" }} />
          Pterodactyl · Pelican · Feather · Wisp · Docker
        </p>
      </FadeIn>

      <FadeIn delay={0.08}>
        <h1 className="grad-text mt-8 max-w-4xl text-5xl font-extrabold leading-[1.08] tracking-tight sm:text-7xl">
          One egg.
          <br />
          Every shell.
          <br />
          Every direction.
        </h1>
      </FadeIn>

      <FadeIn delay={0.16}>
        <p className="mt-6 max-w-2xl text-[1.04em]" style={{ color: "var(--muted)" }}>
          A universal multi-shell egg hosting{" "}
          <NumberTicker value={TOTAL_SHELLS} className="font-bold text-white" /> shell types: SSH with real CA
          certificates, hardened keys-only, tunnels, interpreter reverse shells, TLS and covert channels, bind
          shells, browser terminals and debug harnesses. Credentials are the only mandatory setting.
        </p>
      </FadeIn>

      <FadeIn delay={0.24}>
        <div className="mt-8 flex flex-wrap gap-4">
          <ShimmerButton href={`${REPO}#quick-start`}>Deploy the egg</ShimmerButton>
          <a href={REPO_SHELLS_MD} className="btn btn-ghost" target="_blank" rel="noopener">
            Read SHELLs.md
          </a>
          <Link to="/docs" className="btn btn-ghost">
            Documentation
          </Link>
        </div>
      </FadeIn>

      <FadeIn delay={0.3}>
        <div className="mt-12 grid max-w-3xl grid-cols-2 gap-3.5 sm:grid-cols-4">
          {[
            { v: TOTAL_SHELLS, l: "shell types" },
            { v: FAMILIES.length, l: "families" },
            { v: 5, l: "panels + docker" },
            { v: 1, l: "egg json" },
          ].map((s) => (
            <div key={s.l} className="glass p-4 text-center transition-transform hover:-translate-y-0.5">
              <NumberTicker value={s.v} className="grad-text font-mono text-3xl font-extrabold" />
              <p className="mt-1 text-[11.5px] uppercase tracking-[1.4px]" style={{ color: "var(--muted)" }}>
                {s.l}
              </p>
            </div>
          ))}
        </div>
      </FadeIn>

      <FadeIn delay={0.32}>
        <div className="mt-14 grid items-start gap-8 lg:grid-cols-[1fr_1.2fr]">
          <div>
            <div className="glass p-5 font-mono text-sm" style={{ color: "var(--text-2)" }}>
              <span style={{ color: "#f9a8d4" }}>$</span> {typed}
              <span className="caret" />
            </div>
            <p className="mt-4 text-sm" style={{ color: "var(--faint)" }}>
              Set <code>SHELL_TYPE=auto</code> and the console becomes a paginated picker; set it to any id (or a
              comma list) and everything boots unattended. Multiple shells run side by side on multiple panel ports.
            </p>
          </div>
          <BootTerminal />
        </div>
      </FadeIn>
    </header>
  );
}

function Families() {
  return (
    <section className="mx-auto max-w-6xl px-6 py-16">
      <FadeIn>
        <p className="mono-label">The catalog · {FAMILIES.length} families</p>
        <h2 className="doc-h2 mt-3 !mt-0 text-3xl font-extrabold tracking-tight">
          {TOTAL_SHELLS} shells. Eight directions. One startup variable.
        </h2>
        <p className="mt-4 max-w-2xl" style={{ color: "var(--muted)" }}>
          Pick any combination - a hardened SSH server plus a tmux session, a TLS bind shell plus a Python reverse
          shell. The first ported shell takes the panel-assigned port; extras get their own. Every family has its
          own docs page with connection commands.
        </p>
      </FadeIn>
      <div className="mt-10 grid gap-3.5 sm:grid-cols-2 lg:grid-cols-4">
        {FAMILIES.map((f, i) => (
          <FadeIn key={f.id} delay={Math.min(i * 0.06, 0.3)}>
            <Link to={`/docs/shells/${f.slug}`} className="doc-card h-full">
              <div className="flex items-center justify-between">
                <div className="icon-tile">{f.icon}</div>
                <span
                  className="rounded-full px-2.5 py-0.5 font-mono text-[11px] font-semibold"
                  style={{ background: `${f.accent}1f`, color: f.accent, border: `1px solid ${f.accent}44` }}
                >
                  {CATEGORY_COUNTS[f.id] ?? 0} shells
                </span>
              </div>
              <h3 className="mt-3 text-[.98em] font-semibold text-white">{f.label}</h3>
              <p className="text-[.83em] leading-relaxed" style={{ color: "var(--muted)" }}>
                {f.blurb}
              </p>
              <span
                className="mt-auto pt-2 font-mono text-xs opacity-0 transition-opacity duration-200 group-hover:opacity-100"
                style={{ color: "#f9a8d4" }}
                aria-hidden
              >
                →
              </span>
            </Link>
          </FadeIn>
        ))}
      </div>
      <FadeIn delay={0.2}>
        <p className="mt-6 text-sm" style={{ color: "var(--faint)" }}>
          Full connection guides for every entry:{" "}
          <a href={REPO_SHELLS_MD} target="_blank" rel="noopener">
            SHELLs.md
          </a>{" "}
          · also printed to your server console at boot.
        </p>
      </FadeIn>
    </section>
  );
}

function PortPolicy() {
  const items = [
    { k: "Pterodactyl / Pelican / Feather / Wisp", v: "primary shell binds the panel-allocated SERVER_PORT automatically" },
    { k: "Docker / standalone", v: "binds SERVER_PORT (you choose it, default 8888) - no panel required" },
    { k: "Extra shells", v: "SHELL_EXTRA_PORTS positionally, so 3 shells = 3 allocated panel ports" },
    { k: "Reverse + multiplexers", v: "no inbound port at all - they call out or live in-session" },
  ];
  return (
    <section className="mx-auto max-w-6xl px-6 py-16">
      <FadeIn>
        <p className="mono-label">Port policy</p>
        <h2 className="mt-3 text-3xl font-extrabold tracking-tight text-white">Ports that actually work on panels</h2>
      </FadeIn>
      <div className="mt-8 grid gap-3.5 sm:grid-cols-2">
        {items.map((it, i) => (
          <FadeIn key={it.k} delay={i * 0.08}>
            <div className="doc-card">
              <p className="font-mono text-sm font-semibold" style={{ color: "#c4b5fd" }}>
                {it.k}
              </p>
              <p className="text-sm leading-6" style={{ color: "var(--muted)" }}>
                {it.v}
              </p>
            </div>
          </FadeIn>
        ))}
      </div>
    </section>
  );
}

function Verified() {
  const rows = [
    ["SSH password + SFTP + generated credentials", "real sshpass login in CI"],
    ["SSH CA certificates", "signed cert login; wrong principal rejected"],
    ["Hardened keys-only", "password refused, pubkey accepted"],
    ["Telnet + shadow auth", "login OK; bad password rejected"],
    ["Reverse shells (python/nc/bash)", "reached external listener, command round-trip"],
    ["TLS bind shell", "socat OPENSSL round-trip in container"],
  ];
  return (
    <section id="verified" className="mx-auto max-w-6xl px-6 py-16">
      <FadeIn>
        <p className="mono-label">Tested, not claimed</p>
        <h2 className="mt-3 text-3xl font-extrabold tracking-tight text-white">Verified in real container boots</h2>
      </FadeIn>
      <FadeIn delay={0.1}>
        <div className="mt-8 overflow-hidden rounded-[var(--radius)]" style={{ border: "1px solid var(--line)" }}>
          <table className="data-table" style={{ border: "none" }}>
            <tbody>
              {rows.map(([what, how]) => (
                <tr key={what}>
                  <td className="font-medium" style={{ color: "var(--text-2)" }}>
                    {what}
                  </td>
                  <td className="text-right font-mono text-xs whitespace-nowrap" style={{ color: "#34d399" }}>
                    [OK] {how}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </FadeIn>
    </section>
  );
}

function VariablesTeaser() {
  const mandatory = EGG_VARIABLES.find((v) => v.mandatory);
  const featured = EGG_VARIABLES.filter((v) => ["SHELL_TYPE", "SHELL_PASSWORDS", "SHELL_EXTRA_PORTS"].includes(v.env));
  return (
    <section className="mx-auto max-w-6xl px-6 py-16">
      <FadeIn>
        <p className="mono-label">Configuration</p>
        <h2 className="mt-3 text-3xl font-extrabold tracking-tight text-white">
          Credentials mandatory. Everything else optional.
        </h2>
        <p className="mt-4 max-w-2xl" style={{ color: "var(--muted)" }}>
          Every egg variable has a working default. Give it users and passwords (or let it generate crypto-random
          secrets) and the egg is fully operational.
        </p>
      </FadeIn>
      <div className="mt-8 grid gap-3.5 md:grid-cols-3">
        {featured.map((v, i) => (
          <FadeIn key={v.env} delay={i * 0.08}>
            <div className="doc-card h-full">
              <code className="w-fit font-mono text-sm font-semibold">{v.env}</code>
              <p className="text-[.83em] leading-relaxed" style={{ color: "var(--muted)" }}>
                {v.description.split(".")[0]}.
              </p>
            </div>
          </FadeIn>
        ))}
      </div>
      <FadeIn delay={0.2}>
        <div className="mt-8 flex flex-wrap items-center gap-4">
          <Link to="/docs/variables" className="btn btn-primary btn-sm">
            All {EGG_VARIABLES.length} variables
          </Link>
          {mandatory && (
            <span className="chip">
              <span className="rounded bg-rose-400/15 px-1.5 py-0.5 text-[10px] font-bold uppercase text-rose-300">
                required
              </span>
              {mandatory.env} - {mandatory.name}
            </span>
          )}
        </div>
      </FadeIn>
    </section>
  );
}

function CategoriesStrip() {
  const order = ["server", "multiplexer", "tunnel", "reverse", "secure-web", "bind", "web", "debug"];
  return (
    <div className="mx-auto flex max-w-6xl flex-wrap items-center gap-2 px-6 pb-4">
      {order.filter((c) => CATEGORY_COUNTS[c]).map((c) => (
        <Link key={c} to="/docs/shells" className="chip">
          <span style={{ color: CATEGORY_META[c]?.accent }}>●</span> {CATEGORY_META[c]?.label} ({CATEGORY_COUNTS[c]})
        </Link>
      ))}
    </div>
  );
}

export default function Home() {
  return (
    <main>
      <Hero />
      <CategoriesStrip />
      <Families />
      <PortPolicy />
      <VariablesTeaser />
      <Verified />
    </main>
  );
}
