import { useCallback, useEffect, useState } from "react";
import { BASE, withBase } from "./site";

// Minimal history-API router: real multi-page HTML is emitted at build time
// (scripts/prerender.ts) so direct loads and refreshes hit static files; this
// router only smooths in-app navigation.

export function currentRoutePath(): string {
  const p = window.location.pathname;
  if (!p.startsWith(BASE)) return "/";
  let r = p.slice(BASE.length) || "/";
  if (r.endsWith("/")) r = r.slice(0, -1);
  // Prerendered .html twin URLs (docs/scripts/prerender.ts) resolve to the
  // same route as the directory form.
  if (r.endsWith(".html")) r = r.slice(0, -5);
  return r === "" ? "/" : r;
}

export function useRoute(initial?: string): string {
  const [route, setRoute] = useState<string>(() =>
    initial !== undefined ? initial : typeof window === "undefined" ? "/" : currentRoutePath(),
  );
  useEffect(() => {
    const onPop = () => {
      setRoute(currentRoutePath());
    };
    window.addEventListener("popstate", onPop);
    return () => window.removeEventListener("popstate", onPop);
  }, []);
  return route;
}

export function navigate(to: string) {
  history.pushState(null, "", withBase(to));
  window.dispatchEvent(new PopStateEvent("popstate"));
  window.scrollTo({ top: 0 });
}

type LinkProps = {
  to: string;
  children: React.ReactNode;
  className?: string;
  style?: React.CSSProperties;
  title?: string;
  ariaLabel?: string;
};

// Internal link: intercepts clicks for SPA nav; degrades to a plain <a> when
// modified-clicked (new tab) or when JS navigation is unavailable.
export function Link({ to, children, className, style, title, ariaLabel }: LinkProps) {
  const onClick = useCallback(
    (e: React.MouseEvent) => {
      if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
      e.preventDefault();
      navigate(to);
    },
    [to],
  );
  return (
    <a href={withBase(to)} onClick={onClick} className={className} style={style} title={title} aria-label={ariaLabel}>
      {children}
    </a>
  );
}

// Static prerender (scripts/prerender.ts) writes the correct title/meta into
// each route's HTML; this syncs the head after client-side navigation.
export function useHeadSync(title: string, description: string, path: string) {
  useEffect(() => {
    document.title = title;
    let desc = document.head.querySelector('meta[name="description"]');
    if (!desc) {
      desc = document.createElement("meta");
      desc.setAttribute("name", "description");
      document.head.appendChild(desc);
    }
    desc.setAttribute("content", description);
    const ogTitle = document.head.querySelector('meta[property="og:title"]');
    if (ogTitle) ogTitle.setAttribute("content", title);
    const ogDesc = document.head.querySelector('meta[property="og:description"]');
    if (ogDesc) ogDesc.setAttribute("content", description);
    const canonical = document.head.querySelector('link[rel="canonical"]');
    if (canonical) {
      const url = `https://shell-eggs.docs.potenfyr.in${path === "/" ? "/" : path}`;
      canonical.setAttribute("href", url);
    }
  }, [title, description, path]);
}
