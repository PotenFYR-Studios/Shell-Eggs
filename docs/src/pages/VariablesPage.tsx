import { FadeIn } from "../components/magic";
import { Link } from "../router";
import { DocsShell } from "../components/DocsShell";
import { EGG_VARIABLES } from "../data/catalog";

export default function VariablesPage({ route }: { route: string }) {
  return (
    <DocsShell
      route={route}
      crumbs={[{ label: "Docs", to: "/docs" }, { label: "Variables" }]}
    >
      <FadeIn>
        <p className="eyebrow">Shell-Eggs Docs · Configuration</p>
        <h1 className="grad-text mt-6 text-4xl font-extrabold tracking-tight">Startup variables</h1>
        <p className="mt-4 max-w-2xl" style={{ color: "var(--muted)" }}>
          The complete table from <code>egg-shell-multi.json</code> - {EGG_VARIABLES.length} variables, every one
          with a working default. <strong>SHELL_USERS</strong> (the login users) is mandatory in practice;{" "}
          <code>auto</code> password slots generate crypto-random secrets that are shown once and persisted
          mode-600.
        </p>
      </FadeIn>

      <FadeIn delay={0.08}>
        <table className="data-table mt-10">
          <thead>
            <tr>
              <th>Variable</th>
              <th>Name</th>
              <th>Description</th>
              <th>Default</th>
            </tr>
          </thead>
          <tbody>
            {EGG_VARIABLES.map((v) => (
              <tr key={v.env}>
                <td className="whitespace-nowrap">
                  <div className="flex items-center gap-2">
                    <code className="font-mono font-semibold">{v.env}</code>
                    {v.mandatory ? (
                      <span className="rounded bg-rose-400/15 px-1.5 py-0.5 text-[10px] font-bold uppercase text-rose-300">
                        required
                      </span>
                    ) : (
                      <span
                        className="rounded px-1.5 py-0.5 text-[10px] font-bold uppercase"
                        style={{ background: "rgba(255,255,255,.06)", color: "var(--muted)" }}
                      >
                        optional
                      </span>
                    )}
                  </div>
                </td>
                <td className="whitespace-nowrap text-[.85em]">{v.name}</td>
                <td className="text-[.85em]">{v.description}</td>
                <td className="whitespace-nowrap font-mono text-xs" style={{ color: "var(--faint)" }}>
                  {v.defaultValue === "" ? "empty" : v.defaultValue.length > 48 ? `${v.defaultValue.slice(0, 45)}...` : v.defaultValue}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </FadeIn>

      <FadeIn delay={0.12}>
        <div className="glass mt-10 p-5">
          <p className="text-sm" style={{ color: "var(--muted)" }}>
            Port pairing rule: the primary ported shell binds the panel port (<code>SERVER_PORT</code>); extra
            ported shells consume <code>SHELL_EXTRA_PORTS</code> positionally in the order of{" "}
            <code>SHELL_EXTRA_TYPES</code>. Reverse shells and multiplexers never need an inbound port. See{" "}
            <Link to="/docs/install">the install guide</Link> for the panel allocation walkthrough.
          </p>
        </div>
      </FadeIn>
    </DocsShell>
  );
}
