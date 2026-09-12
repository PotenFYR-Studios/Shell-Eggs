import { FadeIn } from "../components/magic";
import { Link } from "../router";
import { DocsShell, type TocItem } from "../components/DocsShell";
import { Tabs } from "../components/Tabs";
import { DOCKER_RUN, EGG_JSON, EGGS_RAW, IMAGE, PANEL_STEPS, REPO, STARTUP_CMD } from "../site";
import { EGG_VARIABLES } from "../data/catalog";

const TOC: TocItem[] = [
  { id: "docker-images", label: "Docker images" },
  { id: "startup-command", label: "Startup command" },
  { id: "after-first-boot", label: "After the first boot" },
];

export default function Install({ route }: { route: string }) {
  return (
    <DocsShell
      route={route}
      crumbs={[{ label: "Docs", to: "/docs" }, { label: "Install" }]}
      toc={TOC}
    >
      <FadeIn>
        <p className="eyebrow">Shell-Eggs Docs · Install</p>
        <h1 className="grad-text mt-6 text-4xl font-extrabold tracking-tight">Install the egg</h1>
        <p className="mt-4" style={{ color: "var(--muted)" }}>
          One egg JSON, one Docker image, every shell. Import it into any panel - or skip the panel and run the
          image directly. Credentials (<code>SHELL_USERS</code>) are the only mandatory input.
        </p>
      </FadeIn>

      <Tabs
        label="Installation methods"
        tabs={[
          {
            id: "panel",
            label: "Panel import",
            content: (
              <>
                <p className="text-sm" style={{ color: "var(--text-2)" }}>
                  The same five steps work on Pterodactyl, Pelican, Feather and Wisp:
                </p>
                <ol className="mt-4 space-y-3">
                  {PANEL_STEPS.map((s, i) => (
                    <li key={s.step} className="doc-card" style={{ flexDirection: "row", gap: 14, alignItems: "baseline" }}>
                      <span
                        className="font-mono text-xs font-bold"
                        style={{ color: "#f9a8d4", border: "1px solid var(--line)", background: "rgba(139,92,246,.12)", borderRadius: 999, padding: "2px 9px", whiteSpace: "nowrap" }}
                      >
                        {String(i + 1).padStart(2, "0")}
                      </span>
                      <span>
                        <strong className="text-sm text-white">{s.step}.</strong>{" "}
                        <span className="text-sm" style={{ color: "var(--muted)" }}>
                          {s.detail}
                        </span>
                      </span>
                    </li>
                  ))}
                </ol>
                <p className="mt-4 text-sm" style={{ color: "var(--faint)" }}>
                  Egg JSON:{" "}
                  <a href={EGG_JSON} target="_blank" rel="noopener">
                    egg-shell-multi.json
                  </a>{" "}
                  · raw (update_url):{" "}
                  <a href={EGGS_RAW} target="_blank" rel="noopener">
                    raw.githubusercontent.com/.../master/egg-shell-multi.json
                  </a>
                </p>
              </>
            ),
          },
          {
            id: "docker",
            label: "Docker / standalone",
            content: (
              <>
                <pre data-lang="bash">
                  <code>{DOCKER_RUN}</code>
                </pre>
                <p className="mt-3 text-sm" style={{ color: "var(--muted)" }}>
                  Without a panel, <code>SERVER_PORT</code> defaults to <code>8888</code> - map it with{" "}
                  <code>-p</code> and forward every extra ported shell you enable via <code>SHELL_EXTRA_PORTS</code>.
                </p>
              </>
            ),
          },
        ]}
      />

      <h2 className="doc-h2" id="docker-images">
        Docker images
      </h2>
      <FadeIn>
        <table className="data-table">
          <thead>
            <tr>
              <th>Image</th>
              <th>Contents</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>
                <code>{IMAGE}</code>
              </td>
              <td>
                Universal Multi-Shell (All Types) - every tool the catalog needs: sshd, dropbear, telnetd, mosh,
                tmux/screen/zellij, socat/ncat/nc, python, php, node, perl, ruby, lua, go, java, powershell, ttyd,
                gotty and the debug harnesses.
              </td>
            </tr>
          </tbody>
        </table>
        <p className="mt-3 text-sm" style={{ color: "var(--faint)" }}>
          Multi-arch (amd64 + arm64), rebuilt on every push -{" "}
          <a href={`${REPO}/pkgs/container/shell-eggs`} target="_blank" rel="noopener">
            GHCR package
          </a>
          .
        </p>
      </FadeIn>

      <h2 className="doc-h2" id="startup-command">
        Startup command
      </h2>
      <FadeIn>
        <p className="text-sm" style={{ color: "var(--muted)" }}>
          The egg's startup command boots the entrypoint from the image, the server dir, or - as a last resort -
          fetches it from the repo, so old installs self-bootstrap:
        </p>
        <pre className="mt-3" data-lang="startup">
          <code>{STARTUP_CMD}</code>
        </pre>
        <p className="mt-3 text-sm" style={{ color: "var(--faint)" }}>
          It is preconfigured in the egg JSON - you never type it. Self-update defaults to the raw egg on{" "}
          <code>master</code> (<code>EGG_UPDATE_URL</code>, <code>AUTO_UPDATE_EGG=1</code>).
        </p>
      </FadeIn>

      <h2 className="doc-h2" id="after-first-boot">
        After the first boot
      </h2>
      <FadeIn>
        <ul className="space-y-2 text-sm" style={{ color: "var(--text-2)" }}>
          <li>
            <strong>Generated credentials</strong> are printed once on the console and persisted to{" "}
            <code>.env</code> and <code>.sh-users/credentials</code> (mode 600).
          </li>
          <li>
            <strong>SHELL_TYPE=auto</strong> opens the interactive paginated picker in the console.
          </li>
          <li>
            Every boot prints the <strong>connection guide</strong> for the shell you chose - the same content as{" "}
            <Link to="/docs/shells">the family pages</Link>.
          </li>
        </ul>
        <div className="mt-6 flex flex-wrap gap-4">
          <Link to="/docs/variables" className="btn btn-primary btn-sm">
            Variable reference
          </Link>
          <Link to="/examples" className="btn btn-ghost btn-sm">
            Which shell mode?
          </Link>
        </div>
        <p className="mt-6 text-xs" style={{ color: "var(--faint)" }}>
          {EGG_VARIABLES.length} variables in the egg JSON · updated automatically on every build via{" "}
          <code>docs/scripts/sync-data.ts</code>.
        </p>
      </FadeIn>
    </DocsShell>
  );
}
