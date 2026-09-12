import { StrictMode } from "react";
import { createRoot, hydrateRoot } from "react-dom/client";
import App from "./App";
import "./index.css";

const rootEl = document.getElementById("root")!;
// Prerendered pages (scripts/prerender.ts) ship full SSR markup inside #root,
// hydrate it for an instant paint with no re-render flash. The dev server and
// any non-prerendered shell have an empty #root, so render fresh there.
if (rootEl.hasChildNodes()) {
  hydrateRoot(
    rootEl,
    <StrictMode>
      <App />
    </StrictMode>,
  );
} else {
  createRoot(rootEl).render(
    <StrictMode>
      <App />
    </StrictMode>,
  );
}
