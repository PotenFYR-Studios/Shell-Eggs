import { useEffect } from "react";
import { Navbar, Footer, Backdrop, useCopyButtons } from "./components/Chrome";
import { useRoute, useHeadSync, Link } from "./router";
import { ROUTES, FAMILIES, familyBySlug, familyRoute, REPO } from "./site";
import Home from "./pages/Home";
import Docs from "./pages/Docs";
import Install from "./pages/Install";
import VariablesPage from "./pages/VariablesPage";
import ShellFamily from "./pages/ShellFamily";
import Examples from "./pages/Examples";
import About from "./pages/About";
import License from "./pages/License";
import ShellCatalog from "./Catalog";

const META: Record<string, { title: string; description: string }> = Object.fromEntries(
  [...ROUTES, ...FAMILIES.map(familyRoute)].map((r) => [r.path, { title: r.title, description: r.description }]),
);

function NotFound({ route }: { route: string }) {
  return (
    <main className="mx-auto max-w-3xl px-6 py-24 text-center">
      <p className="eyebrow">404 · uncharted shell</p>
      <h1 className="grad-text mt-6 text-4xl font-extrabold tracking-tight sm:text-5xl">No shell at this path</h1>
      <p className="mt-4" style={{ color: "var(--muted)" }}>
        <code>{route}</code> does not exist. The catalog, docs and examples are one click away.
      </p>
      <div className="mt-8 flex flex-wrap justify-center gap-4">
        <Link to="/docs" className="btn btn-primary">
          Open the docs
        </Link>
        <a href={REPO} className="btn btn-ghost" target="_blank" rel="noopener">
          GitHub repository
        </a>
      </div>
    </main>
  );
}

function Page({ route }: { route: string }) {
  if (route === "/") return <Home />;
  if (route === "/docs") return <Docs route={route} />;
  if (route === "/docs/install") return <Install route={route} />;
  if (route === "/docs/variables") return <VariablesPage route={route} />;
  if (route === "/docs/shells") return <ShellCatalog route={route} />;
  if (route.startsWith("/docs/shells/")) {
    const fam = familyBySlug(route.slice("/docs/shells/".length));
    return fam ? <ShellFamily family={fam} route={route} /> : <NotFound route={route} />;
  }
  if (route === "/examples") return <Examples route={route} />;
  if (route === "/about") return <About />;
  if (route === "/license") return <License route={route} />;
  return <NotFound route={route} />;
}

export default function App({ initialRoute }: { initialRoute?: string } = {}) {
  const route = useRoute(initialRoute);
  // META keys are route-relative ("" for home); useRoute normalizes home to "/".
  const meta = META[route === "/" ? "" : route] ?? {
    title: "Page not found - Shell-Eggs",
    description: "This Shell-Eggs page could not be found. Head to the catalog home or the GitHub repository.",
  };
  useHeadSync(meta.title, meta.description, route);
  useCopyButtons(route);
  useEffect(() => {
    window.scrollTo({ top: 0 });
  }, [route]);
  return (
    <div className="relative flex min-h-screen flex-col">
      <Backdrop />
      <Navbar />
      <div className="relative z-[1] flex-1">
        <Page route={route} />
      </div>
      <Footer />
    </div>
  );
}
