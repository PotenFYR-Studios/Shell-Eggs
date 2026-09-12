// Server-only entry: renders the full App tree to static HTML for one route.
// Loaded by scripts/prerender.ts through vite.ssrLoadModule (never bundled;
// nothing in the client graph imports this file).
import { renderToString } from "react-dom/server";
import App from "./App";

export function renderPage(route: string): string {
  return renderToString(<App initialRoute={route} />);
}
