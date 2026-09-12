import { useState } from "react";

export type TabDef = { id: string; label: string; content: React.ReactNode };

// Tabbed alternatives (W5). Every panel stays in the DOM behind the `hidden`
// attribute, so the prerendered HTML carries all tabs' content for crawlers;
// only `hidden` toggles after hydration (initial state is deterministic, so
// hydration matches exactly).
export function Tabs({ tabs, label }: { tabs: TabDef[]; label: string }) {
  const [active, setActive] = useState(tabs[0]?.id);
  return (
    <div className="mt-10">
      <div role="tablist" aria-label={label} className="tab-list">
        {tabs.map((t) => (
          <button
            key={t.id}
            type="button"
            role="tab"
            aria-selected={active === t.id}
            className="tab-btn"
            onClick={() => setActive(t.id)}
          >
            {t.label}
          </button>
        ))}
      </div>
      {tabs.map((t) => (
        <div key={t.id} role="tabpanel" hidden={active !== t.id}>
          {t.content}
        </div>
      ))}
    </div>
  );
}
