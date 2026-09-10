import { EGG_VARIABLES } from "./data/catalog";
import { FadeIn } from "./components/magic";

export default function Variables() {
  return (
    <section id="variables" className="mx-auto max-w-5xl px-6 py-24">
      <FadeIn>
        <p className="text-sm font-semibold uppercase tracking-[0.25em] text-fuchsia-300">Configuration</p>
        <h2 className="mt-3 text-3xl font-bold text-white sm:text-4xl">Credentials mandatory. Everything else optional.</h2>
        <p className="mt-4 max-w-2xl text-slate-400">
          Every egg variable has a working default. Give it users and passwords (or let it generate crypto-random
          secrets) and the egg is fully operational - everything below is opt-in.
        </p>
      </FadeIn>

      <div className="mt-10 space-y-3">
        {EGG_VARIABLES.map((v, i) => (
          <FadeIn key={v.env} delay={Math.min(i * 0.03, 0.4)}>
            <div className="flex flex-col gap-1 rounded-xl border border-slate-700/40 bg-slate-900/50 px-5 py-4 sm:flex-row sm:items-center sm:gap-6">
              <div className="sm:w-72">
                <div className="flex items-center gap-2">
                  <code className="font-mono text-sm font-semibold text-cyan-300">{v.env}</code>
                  {v.mandatory ? (
                    <span className="rounded bg-rose-400/15 px-1.5 py-0.5 text-[10px] font-bold uppercase text-rose-300">required</span>
                  ) : (
                    <span className="rounded bg-slate-600/25 px-1.5 py-0.5 text-[10px] font-bold uppercase text-slate-400">optional</span>
                  )}
                </div>
                <p className="mt-1 text-sm text-slate-300">{v.name}</p>
              </div>
              <p className="flex-1 text-[13px] leading-5 text-slate-400">{v.description}</p>
              <code className="font-mono text-xs text-slate-500 sm:w-44 sm:text-right" title="default value">
                {v.defaultValue === "" ? "empty" : v.defaultValue}
              </code>
            </div>
          </FadeIn>
        ))}
      </div>
    </section>
  );
}
