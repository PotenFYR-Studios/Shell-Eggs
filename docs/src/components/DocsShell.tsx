import { useState } from "react";
import { Link } from "../router";
import { DOCS_GROUPS, DOCS_ORDER, type DocsNavItem } from "../site";

export type TocItem = { id: string; label: string };
export type Crumb = { label: string; to?: string };

function PagerCard({ item, dir }: { item: DocsNavItem | undefined; dir: "prev" | "next" }) {
  if (!item) return <div className="hidden flex-1 sm:block" aria-hidden />;
  return (
    <Link
      to={item.path}
      className={`doc-card flex-1 flex-row items-center justify-between${dir === "next" ? " text-right" : ""}`}
    >
      <div className={dir === "next" ? "ml-auto" : undefined}>
        <p className="mono-label">{dir === "prev" ? "← Previous" : "Next →"}</p>
        <p className="mt-1 text-sm font-semibold text-white">{item.label}</p>
      </div>
    </Link>
  );
}

// Docs shell (W5): grouped sidebar (active highlighting + client-side page
// filter), breadcrumbs, per-page TOC right rail (only for 3+ headings; hidden
// on short pages and mobile) and prev/next pagination in sidebar order.
// `route` arrives as a prop from App so the prerendered HTML is deterministic
// on the server and hydrates without warnings.
export function DocsShell({
  route,
  crumbs = [],
  toc,
  children,
}: {
  route: string;
  crumbs?: Crumb[];
  toc?: TocItem[];
  children: React.ReactNode;
}) {
  const [query, setQuery] = useState("");
  const q = query.trim().toLowerCase();
  const idx = DOCS_ORDER.findIndex((i) => i.path === route);
  const prev = idx > 0 ? DOCS_ORDER[idx - 1] : undefined;
  const next = idx >= 0 && idx < DOCS_ORDER.length - 1 ? DOCS_ORDER[idx + 1] : undefined;
  const tocItems = toc && toc.length >= 3 ? toc : undefined;

  return (
    <div className="mx-auto w-full max-w-6xl px-6 pb-24 pt-20">
      {crumbs.length > 0 && (
        <nav className="crumbs" aria-label="Breadcrumb">
          {crumbs.map((c, i) => (
            <span key={i} className="crumb">
              {i > 0 && (
                <span className="crumb-sep" aria-hidden>
                  /
                </span>
              )}
              {c.to ? <Link to={c.to}>{c.label}</Link> : <span aria-current="page">{c.label}</span>}
            </span>
          ))}
        </nav>
      )}
      <div className={`docs-layout${tocItems ? " has-toc" : ""}`}>
        <aside className="docs-sidebar" aria-label="Docs navigation">
          <input
            type="search"
            className="docs-filter"
            placeholder="Filter pages..."
            aria-label="Filter docs pages"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
          {DOCS_GROUPS.map((g) => {
            const items = g.items.filter((it) => !q || it.label.toLowerCase().includes(q));
            if (items.length === 0) return null;
            return (
              <details key={g.label} className="nav-group" open>
                <summary>{g.label}</summary>
                <ul>
                  {items.map((it) => (
                    <li key={it.path}>
                      <Link to={it.path} className={`doc-nav-link${route === it.path ? " active" : ""}`}>
                        {it.label}
                      </Link>
                    </li>
                  ))}
                </ul>
              </details>
            );
          })}
        </aside>
        <div className="docs-article">
          {children}
          <div className="doc-pager mt-14 flex justify-between gap-4">
            <PagerCard item={prev} dir="prev" />
            <PagerCard item={next} dir="next" />
          </div>
        </div>
        {tocItems && (
          <aside className="toc-rail" aria-label="On this page">
            <p className="mono-label">On this page</p>
            <ul>
              {tocItems.map((t) => (
                <li key={t.id}>
                  <a href={`#${t.id}`} className="toc-link">
                    {t.label}
                  </a>
                </li>
              ))}
            </ul>
          </aside>
        )}
      </div>
    </div>
  );
}
