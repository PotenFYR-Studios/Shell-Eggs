import { useState } from "react";
import { SHELLS, CATEGORY_META, CATEGORY_COUNTS, TOTAL_SHELLS } from "./data/catalog";
import { FadeIn } from "./components/magic";

const ORDER = ["server", "multiplexer", "tunnel", "reverse", "secure-web", "bind", "web", "debug"];

export default function Catalog() {
  const [active, setActive] = useState<string>("all");
  const [query, setQuery] = useState("");

  const visible = SHELLS.filter((s) => {
    const inCat = active === "all" || s.category === active;
    const q = query.trim().toLowerCase();
    const inQuery = q === "" || s.id.includes(q) || s.name.toLowerCase().includes(q) || s.description.toLowerCase().includes(q);
    return inCat && inQuery;
  });

  return (
    <section id="catalog" className="mx-auto max-w-6xl px-6 py-24">
      <FadeIn>
        <p className="text-sm font-semibold uppercase tracking-[0.25em] text-cyan-300">The Catalog</p>
        <h2 className="mt-3 text-3xl font-bold text-white sm:text-4xl">
          {TOTAL_SHELLS} shells. 7 directions. One startup variable.
        </h2>
        <p className="mt-4 max-w-2xl text-slate-400">
          Pick any combination - a hardened SSH server plus a tmux session, a TLS bind shell plus a Python reverse
          shell. The first ported shell takes the panel-assigned port; extras get their own. Full connection guides
          for every entry live in <a className="text-cyan-300 underline decoration-dotted" href="https://github.com/PotenFYR-Studios/Shell-Eggs/blob/main/SHELLs.md" target="_blank" rel="noreferrer">SHELLs.md</a>.
        </p>
      </FadeIn>

      <FadeIn delay={0.1}>
        <div className="mt-10 flex flex-wrap items-center gap-2">
          <button
            onClick={() => setActive("all")}
            className={`rounded-full px-4 py-1.5 text-sm font-medium transition ${
              active === "all" ? "bg-cyan-400 text-slate-950" : "bg-slate-800/60 text-slate-300 hover:bg-slate-700/60"
            }`}
          >
            All ({TOTAL_SHELLS})
          </button>
          {ORDER.filter((c) => CATEGORY_COUNTS[c]).map((c) => (
            <button
              key={c}
              onClick={() => setActive(c)}
              className={`rounded-full px-4 py-1.5 text-sm font-medium transition ${
                active === c ? "text-slate-950" : "bg-slate-800/60 text-slate-300 hover:bg-slate-700/60"
              }`}
              style={active === c ? { background: CATEGORY_META[c].accent } : {}}
            >
              {CATEGORY_META[c].label} ({CATEGORY_COUNTS[c]})
            </button>
          ))}
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="filter: php, tls, tunnel..."
            className="ml-auto w-56 rounded-full border border-slate-700/60 bg-slate-900/60 px-4 py-1.5 text-sm text-slate-200 outline-none placeholder:text-slate-500 focus:border-cyan-400/60"
          />
        </div>
      </FadeIn>

      <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {visible.map((s, i) => (
          <FadeIn key={s.id} delay={Math.min(i * 0.02, 0.3)}>
            <div className="group h-full rounded-2xl border border-slate-700/40 bg-slate-900/50 p-5 backdrop-blur transition hover:border-cyan-400/40 hover:bg-slate-800/40">
              <div className="flex items-center justify-between">
                <span
                  className="rounded-full px-2.5 py-0.5 text-[11px] font-semibold uppercase tracking-wide"
                  style={{ background: `${CATEGORY_META[s.category]?.accent ?? "#22d3ee"}1f`, color: CATEGORY_META[s.category]?.accent }}
                >
                  {CATEGORY_META[s.category]?.label ?? s.category}
                </span>
                {s.needsRoot && (
                  <span className="text-[11px] text-slate-500" title="prefers root in-container">root</span>
                )}
              </div>
              <h3 className="mt-3 font-mono text-base font-semibold text-white">{s.id}</h3>
              <p className="mt-1 text-sm font-medium text-slate-300">{s.name}</p>
              <p className="mt-2 text-[13px] leading-5 text-slate-400">{s.description}</p>
              <p className="mt-3 font-mono text-[11px] text-slate-500">
                {s.defaultPort === 0 ? "no inbound port" : `default port ${s.defaultPort}`}
              </p>
            </div>
          </FadeIn>
        ))}
      </div>

      {visible.length === 0 && (
        <p className="mt-12 text-center text-slate-500">Nothing matches "{query}". Try: ssh, php, tls, tunnel.</p>
      )}
    </section>
  );
}
