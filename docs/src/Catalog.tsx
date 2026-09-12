import { useState } from "react";
import { SHELLS, CATEGORY_META, CATEGORY_COUNTS, TOTAL_SHELLS } from "./data/catalog";
import { FadeIn } from "./components/magic";
import { DocsShell } from "./components/DocsShell";

const ORDER = ["server", "multiplexer", "tunnel", "reverse", "secure-web", "bind", "web", "debug"];

export default function Catalog({ route }: { route: string }) {
  const [active, setActive] = useState<string>("all");
  const [query, setQuery] = useState("");

  const visible = SHELLS.filter((s) => {
    const inCat = active === "all" || s.category === active;
    const q = query.trim().toLowerCase();
    const inQuery = q === "" || s.id.includes(q) || s.name.toLowerCase().includes(q) || s.description.toLowerCase().includes(q);
    return inCat && inQuery;
  });

  return (
    <DocsShell route={route} crumbs={[{ label: "Docs", to: "/docs" }, { label: "Shells" }]}>
      <section id="catalog">
      <FadeIn>
        <p className="mono-label">The Catalog</p>
        <h2 className="mt-3 text-3xl font-extrabold tracking-tight text-white">
          {TOTAL_SHELLS} shells. Eight directions. One startup variable.
        </h2>
        <p className="mt-4 max-w-2xl" style={{ color: "var(--muted)" }}>
          Pick any combination - a hardened SSH server plus a tmux session, a TLS bind shell plus a Python reverse
          shell. The first ported shell takes the panel-assigned port; extras get their own. Full connection guides
          for every entry live in{" "}
          <a
            className="underline decoration-dotted"
            href="https://github.com/PotenFYR-Studios/Shell-Eggs/blob/master/SHELLs.md"
            target="_blank"
            rel="noreferrer"
          >
            SHELLs.md
          </a>
          .
        </p>
      </FadeIn>

      <FadeIn delay={0.1}>
        <div className="mt-10 flex flex-wrap items-center gap-2">
          <button
            onClick={() => setActive("all")}
            className="chip"
            style={{
              background: active === "all" ? "var(--violet)" : undefined,
              color: active === "all" ? "#fff" : undefined,
              border: active === "all" ? "1px solid var(--violet)" : undefined,
            }}
          >
            All ({TOTAL_SHELLS})
          </button>
          {ORDER.filter((c) => CATEGORY_COUNTS[c]).map((c) => (
            <button
              key={c}
              onClick={() => setActive(c)}
              className="chip"
              style={{
                background: active === c ? CATEGORY_META[c].accent : undefined,
                color: active === c ? "#fff" : undefined,
                border: active === c ? `1px solid ${CATEGORY_META[c].accent}` : undefined,
              }}
            >
              {CATEGORY_META[c].label} ({CATEGORY_COUNTS[c]})
            </button>
          ))}
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="filter: php, tls, tunnel..."
            className="ml-auto w-56 rounded-full border border-white/10 bg-white/[0.03] px-4 py-1.5 text-sm outline-none placeholder:text-[#6a7089] focus:border-[#8b5cf6]"
            style={{ color: "var(--text-2)" }}
          />
        </div>
      </FadeIn>

      <div className="mt-8 grid gap-3.5 sm:grid-cols-2 lg:grid-cols-3">
        {visible.map((s, i) => (
          <FadeIn key={s.id} delay={Math.min(i * 0.02, 0.3)}>
            <div className="doc-card group h-full">
              <div className="flex items-center justify-between">
                <span
                  className="rounded-full px-2.5 py-0.5 font-mono text-[11px] font-semibold uppercase tracking-wide"
                  style={{
                    background: `${CATEGORY_META[s.category]?.accent ?? "#c4b5fd"}1f`,
                    color: CATEGORY_META[s.category]?.accent,
                  }}
                >
                  {CATEGORY_META[s.category]?.label ?? s.category}
                </span>
                {s.needsRoot && (
                  <span className="text-[11px]" style={{ color: "var(--faint)" }} title="prefers root in-container">
                    root
                  </span>
                )}
              </div>
              <h3 className="mt-3 font-mono text-base font-semibold text-white">{s.id}</h3>
              <p className="mt-1 text-sm font-medium" style={{ color: "var(--text-2)" }}>
                {s.name}
              </p>
              <p className="mt-2 text-[13px] leading-5" style={{ color: "var(--muted)" }}>
                {s.description}
              </p>
              <p className="mt-3 font-mono text-[11px]" style={{ color: "var(--faint)" }}>
                {s.defaultPort === 0 ? "no inbound port" : `default port ${s.defaultPort}`}
              </p>
            </div>
          </FadeIn>
        ))}
      </div>

      {visible.length === 0 && (
        <p className="mt-12 text-center" style={{ color: "var(--faint)" }}>
          Nothing matches "{query}". Try: ssh, php, tls, tunnel.
        </p>
      )}
      </section>
    </DocsShell>
  );
}
