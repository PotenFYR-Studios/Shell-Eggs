import { useEffect, useState } from "react";
import { Link, useRoute } from "../router";
import { REPO, withBase } from "../site";

const NAV = [
  { to: "/", label: "Home" },
  { to: "/docs", label: "Docs" },
  { to: "/examples", label: "Examples" },
  { to: "/about", label: "About" },
];

function isActive(route: string, to: string): boolean {
  if (to === "/") return route === "/";
  return route === to || route.startsWith(`${to}/`);
}

export function Navbar() {
  const route = useRoute();
  const [open, setOpen] = useState(false);
  useEffect(() => setOpen(false), [route]);
  return (
    <header className="site-header">
      <Link to="/" className="brand" ariaLabel="Shell-Eggs home">
        <img src={withBase("/favicon.png")} alt="" width={24} height={24} style={{ borderRadius: 6 }} />
        <span>
          Shell-Eggs<span style={{ color: "var(--pink)" }}>.</span>site
        </span>
      </Link>
      <nav className="hidden md:flex items-center gap-1" aria-label="Primary">
        {NAV.map((n) => (
          <Link key={n.to} to={n.to} className={`nav-link${isActive(route, n.to) ? " active" : ""}`}>
            {n.label}
          </Link>
        ))}
      </nav>
      <div className="ml-auto hidden md:flex items-center gap-4">
        <a className="nav-ext" href={REPO} target="_blank" rel="noopener">
          GitHub
        </a>
        <a className="nav-ext" href="https://potenfyr.in" target="_blank" rel="noopener">
          Website
        </a>
        <a className="nav-ext" href="https://discord.com/invite/zUaN2FPBec" target="_blank" rel="noopener">
          Discord
        </a>
      </div>
      <button
        className="ml-auto md:hidden rounded-lg border border-white/10 bg-white/5 px-3 py-1.5"
        aria-expanded={open}
        aria-label="Toggle navigation"
        onClick={() => setOpen((v) => !v)}
      >
        <span className="block w-4 border-t-2 border-[#e8eaf2]" />
        <span className="block w-4 border-t-2 border-[#e8eaf2] mt-1" />
        <span className="block w-4 border-t-2 border-[#e8eaf2] mt-1" />
      </button>
      {open && (
        <div
          className="absolute left-0 right-0 flex flex-col gap-1 px-5 py-4 md:hidden"
          style={{ top: "var(--header-h)", background: "rgba(11,13,20,.98)", borderBottom: "1px solid var(--line-light)" }}
        >
          {NAV.map((n) => (
            <Link key={n.to} to={n.to} className={`nav-link${isActive(route, n.to) ? " active" : ""}`}>
              {n.label}
            </Link>
          ))}
          <a className="nav-link" href={REPO} target="_blank" rel="noopener">
            GitHub ↗
          </a>
        </div>
      )}
    </header>
  );
}

export function Footer() {
  return (
    <footer className="site-footer">
      <div className="sf-inner">
        <div className="flex flex-col gap-6 md:flex-row md:items-start md:justify-between">
          <div style={{ maxWidth: 420 }}>
            <p className="font-mono font-bold text-[#fff] flex items-center gap-2">
              Shell-Eggs
              <span
                className="grad-text"
                style={{ fontSize: "1.2em", lineHeight: 1 }}
                aria-hidden
              >
                .
              </span>
            </p>
            <p className="mt-2" style={{ fontSize: ".8em", color: "var(--muted)" }}>
              One universal egg hosting every shell direction - incoming, tunneled, reversed, encrypted, covert,
              web and debug. Credentials are the only mandatory input.
            </p>
          </div>
          <div className="sf-links md:justify-end md:text-right">
            <a href={REPO} target="_blank" rel="noopener">
              GitHub Org
            </a>
            <a href="https://potenfyr.in" target="_blank" rel="noopener">
              potenfyr.in
            </a>
            <a href="https://discord.com/invite/zUaN2FPBec" target="_blank" rel="noopener">
              Support Discord
            </a>
            <a href={`${REPO}/issues`} target="_blank" rel="noopener">
              Issues
            </a>
            <Link to="/docs" className="accent">
              Docs
            </Link>
            <Link to="/license">License</Link>
          </div>
        </div>
        <div className="sf-legal flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
          <span>© 2026 PotenFYR Studios. Released under Apache-2.0 WITH Commons-Clause.</span>
          <span>Crafted with ♥ for the panel community.</span>
        </div>
      </div>
    </footer>
  );
}

// Inject a SPEC §5.8 copy button into every <pre> after each route render.
export function useCopyButtons(route: string) {
  useEffect(() => {
    const inject = () => {
      document.querySelectorAll("pre").forEach((pre) => {
        if (pre.querySelector(".copy-btn")) return;
        const btn = document.createElement("button");
        btn.className = "copy-btn";
        btn.textContent = "Copy";
        btn.setAttribute("aria-label", "Copy code");
        btn.addEventListener("click", () => {
          const text = pre.querySelector("code")?.textContent ?? pre.textContent ?? "";
          navigator.clipboard?.writeText(text).then(
            () => {
              btn.textContent = "Copied!";
              btn.classList.add("ok");
              setTimeout(() => {
                btn.textContent = "Copy";
                btn.classList.remove("ok");
              }, 1400);
            },
            () => {
              btn.textContent = "Error";
            },
          );
        });
        pre.appendChild(btn);
      });
    };
    inject();
    const mo = new MutationObserver(() => inject());
    mo.observe(document.body, { childList: true, subtree: true });
    return () => mo.disconnect();
  }, [route]);
}

// 2px scroll-progress bar (SPEC §7 allowed, gradient + pink glow).
export function ScrollProgress() {
  const [pct, setPct] = useState(0);
  useEffect(() => {
    const onScroll = () => {
      const h = document.documentElement;
      const max = h.scrollHeight - h.clientHeight;
      setPct(max > 0 ? (h.scrollTop / max) * 100 : 0);
    };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);
  return (
    <div
      aria-hidden
      style={{
        position: "fixed",
        top: 0,
        left: 0,
        height: 2,
        width: `${pct}%`,
        zIndex: 600,
        background: "linear-gradient(90deg, #8b5cf6, #ec4899, #f97316)",
        boxShadow: "0 0 8px rgba(236,72,153,.6)",
        pointerEvents: "none",
      }}
    />
  );
}

export function Backdrop() {
  return (
    <>
      <div className="dot-pattern" aria-hidden />
      <ScrollProgress />
    </>
  );
}
