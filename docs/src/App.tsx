import { AuroraBackdrop, BootTerminal, FadeIn, NumberTicker, ShimmerButton, useTypewriter } from "./components/magic";
import Catalog from "./Catalog";
import Variables from "./Variables";
import { TOTAL_SHELLS } from "./data/catalog";

const REPO = "https://github.com/PotenFYR-Studios/Shell-Eggs";

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
    <header className="mx-auto max-w-6xl px-6 pt-28 pb-16">
      <FadeIn>
        <div className="flex flex-wrap items-center gap-3">
          <a href={REPO} className="rounded-full border border-slate-700/60 bg-slate-900/60 px-3 py-1 text-xs text-slate-300">
            Pterodactyl - Pelican - Feather - Wisp - Docker
          </a>
          <span className="rounded-full border border-cyan-400/30 bg-cyan-400/10 px-3 py-1 text-xs font-semibold text-cyan-300">
            MIT - PotenFYR Studios
          </span>
        </div>
      </FadeIn>

      <FadeIn delay={0.08}>
        <h1 className="mt-8 max-w-4xl text-5xl font-black leading-[1.05] tracking-tight text-white sm:text-7xl">
          One egg.
          <br />
          Every shell.
          <br />
          <span className="bg-gradient-to-r from-cyan-300 via-violet-300 to-pink-300 bg-clip-text text-transparent">
            Every direction.
          </span>
        </h1>
      </FadeIn>

      <FadeIn delay={0.16}>
        <p className="mt-6 max-w-2xl text-lg text-slate-400">
          A universal multi-shell egg hosting{" "}
          <NumberTicker value={TOTAL_SHELLS} className="font-bold text-white" /> shell types: SSH with real CA
          certificates, hardened keys-only, tunnels, interpreter reverse shells, TLS and covert channels, bind
          shells, browser terminals and debug harnesses. Credentials are the only mandatory setting.
        </p>
      </FadeIn>

      <FadeIn delay={0.24}>
        <div className="mt-8 flex flex-wrap gap-4">
          <ShimmerButton href={`${REPO}#quick-start`}>Deploy the egg</ShimmerButton>
          <a
            href="https://github.com/PotenFYR-Studios/Shell-Eggs/blob/main/SHELLs.md"
            className="rounded-xl border border-slate-700/60 bg-slate-900/60 px-6 py-3 text-sm font-semibold text-slate-200 transition hover:border-cyan-400/50 hover:text-cyan-300"
          >
            Read SHELLs.md
          </a>
        </div>
      </FadeIn>

      <FadeIn delay={0.32}>
        <div className="mt-14 grid items-start gap-8 lg:grid-cols-[1fr_1.2fr]">
          <div>
            <div className="rounded-2xl border border-slate-700/40 bg-slate-900/50 p-5 font-mono text-sm text-slate-300">
              <span className="text-fuchsia-300">$</span> {typed}
              <span className="caret" />
            </div>
            <p className="mt-4 text-sm text-slate-500">
              Set <code className="text-cyan-300">SHELL_TYPE=auto</code> and the console becomes a paginated picker;
              set it to any id (or a comma list) and everything boots unattended. Multiple shells run side by side on
              multiple panel ports.
            </p>
          </div>
          <BootTerminal />
        </div>
      </FadeIn>
    </header>
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
        <h2 className="text-2xl font-bold text-white sm:text-3xl">Port policy that actually works on panels</h2>
      </FadeIn>
      <div className="mt-8 grid gap-4 sm:grid-cols-2">
        {items.map((it, i) => (
          <FadeIn key={it.k} delay={i * 0.08}>
            <div className="rounded-2xl border border-slate-700/40 bg-slate-900/50 p-6">
              <p className="font-semibold text-cyan-300">{it.k}</p>
              <p className="mt-2 text-sm leading-6 text-slate-400">{it.v}</p>
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
    <section id="verified" className="mx-auto max-w-6xl px-6 py-24">
      <FadeIn>
        <p className="text-sm font-semibold uppercase tracking-[0.25em] text-emerald-300">Tested, not claimed</p>
        <h2 className="mt-3 text-3xl font-bold text-white sm:text-4xl">Verified in real container boots</h2>
      </FadeIn>
      <div className="mt-8 overflow-hidden rounded-2xl border border-slate-700/40">
        {rows.map(([what, how], i) => (
          <FadeIn key={what} delay={i * 0.05}>
            <div className={`flex flex-col gap-1 px-6 py-4 sm:flex-row sm:items-center sm:justify-between ${i % 2 ? "bg-slate-900/40" : "bg-slate-900/60"}`}>
              <p className="text-sm font-medium text-slate-200">{what}</p>
              <p className="font-mono text-xs text-emerald-300">[OK] {how}</p>
            </div>
          </FadeIn>
        ))}
      </div>
    </section>
  );
}

function Footer() {
  return (
    <footer className="border-t border-slate-800/60 py-12">
      <div className="mx-auto flex max-w-6xl flex-col items-center gap-4 px-6 text-center">
        <p className="text-sm text-slate-500">
          Crafted by PotenFYR Studios - shells are dual-use tools; deploy only on systems you own or are authorized
          to test.
        </p>
        <div className="flex gap-4 text-sm">
          <a className="text-slate-400 hover:text-cyan-300" href={REPO}>GitHub</a>
          <a className="text-slate-400 hover:text-cyan-300" href={`${REPO}/blob/main/SHELLs.md`}>SHELLs.md</a>
          <a className="text-slate-400 hover:text-cyan-300" href={`${REPO}/blob/main/egg-shell-multi.json`}>egg JSON</a>
          <a className="text-slate-400 hover:text-cyan-300" href="https://potenfyr.in">potenfyr.in</a>
        </div>
      </div>
    </footer>
  );
}

export default function App() {
  return (
    <main className="min-h-screen">
      <AuroraBackdrop />
      <Hero />
      <Catalog />
      <PortPolicy />
      <Variables />
      <Verified />
      <Footer />
    </main>
  );
}
