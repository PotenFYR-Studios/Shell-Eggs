import { FadeIn } from "../components/magic";
import { Link } from "../router";
import { DocsShell } from "../components/DocsShell";
import { FAMILIES } from "../site";

function Card({ to, icon, title, desc }: { to: string; icon: string; title: string; desc: string }) {
  return (
    <Link to={to} className="doc-card h-full">
      <div className="flex items-center gap-3">
        <div className="icon-tile">{icon}</div>
        <h3 className="text-[.98em] font-semibold text-white">{title}</h3>
      </div>
      <p className="text-[.83em] leading-relaxed" style={{ color: "var(--muted)" }}>
        {desc}
      </p>
    </Link>
  );
}

export default function Docs({ route }: { route: string }) {
  return (
    <DocsShell route={route}>
      <FadeIn>
        <p className="eyebrow">Shell-Eggs Docs</p>
        <h1 className="grad-text mt-6 text-4xl font-extrabold tracking-tight sm:text-5xl">Documentation hub</h1>
        <p className="mt-4 max-w-2xl" style={{ color: "var(--muted)" }}>
          Everything the universal egg can do, from the first panel import to per-family connection guides. The
          catalog is generated from <code>scripts/shell-registry.sh</code> and <code>egg-shell-multi.json</code>, so
          these pages always match what the egg actually ships.
        </p>
      </FadeIn>

      <FadeIn delay={0.08}>
        <p className="mono-label mt-12">Get started</p>
        <div className="mt-4 grid gap-3.5 sm:grid-cols-2 lg:grid-cols-3">
          <Card
            to="/docs/install"
            icon="📦"
            title="Install the egg"
            desc="Import egg-shell-multi.json into Pterodactyl / Pelican / Feather / Wisp, or run the GHCR image with plain Docker. Panel steps, images and the startup command."
          />
          <Card
            to="/docs/variables"
            icon="⚙️"
            title="Startup variables"
            desc="The full variable table straight from the egg JSON: shell selection, users and passwords, ports, reverse targets, SSH hardening, web auth."
          />
          <Card
            to="/docs/shells"
            icon="🗂️"
            title="Shell catalog"
            desc="All 54 shell types with filters and ports - the same catalog the console picker shows."
          />
          <Card
            to="/examples"
            icon="🧭"
            title="Which shell mode?"
            desc="Chooser cards: tell me what you want to do, get the shell id and the exact commands to run on both sides."
          />
        </div>
      </FadeIn>

      <FadeIn delay={0.12}>
        <p className="mono-label mt-12">Shell families</p>
        <div className="mt-4 grid gap-3.5 sm:grid-cols-2 lg:grid-cols-4">
          {FAMILIES.map((f) => (
            <Link key={f.id} to={`/docs/shells/${f.slug}`} className="doc-card h-full">
              <div className="flex items-center gap-3">
                <div className="icon-tile">{f.icon}</div>
                <h3 className="text-[.95em] font-semibold text-white">{f.label}</h3>
              </div>
              <p className="text-[.83em] leading-relaxed" style={{ color: "var(--muted)" }}>
                {f.blurb.split(" - ")[0].split(". ")[0]}.
              </p>
            </Link>
          ))}
        </div>
      </FadeIn>

      <FadeIn delay={0.16}>
        <div className="glass mt-12 p-5">
          <p className="text-sm" style={{ color: "var(--muted)" }}>
            Prefer one long page? The complete reference with connection commands for every shell lives in{" "}
            <a href="https://github.com/PotenFYR-Studios/Shell-Eggs/blob/master/SHELLs.md" target="_blank" rel="noopener">
              SHELLs.md
            </a>{" "}
            - the same guides the console prints at boot.
          </p>
        </div>
      </FadeIn>
    </DocsShell>
  );
}
