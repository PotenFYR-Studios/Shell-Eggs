// Multi-route static generation with REAL body rendering.
//
//   vite dev server (middleware mode) -> ssrLoadModule("src/ssg-entry.tsx")
//   -> renderToString(<App initialRoute={route} />) per route
//   -> injected as the #root div's innerHTML in the emitted file
//
// main.tsx hydrates that markup on the client (hydrateRoot), so crawlers get
// the full page content and users get an instant paint with no re-render
// flash. Every route is emitted twice (twins): dist/<route>/index.html and
// dist/<route>.html; the client router normalizes ".html" URLs to the same
// route. The landing ships the org-standard JSON-LD @graph (WebSite +
// Organization + SoftwareApplication); sub-routes ship a per-route WebPage
// node. Meta (title/description ≤160 chars) has a single source of truth:
// src/site.ts.
//
// Runs after `vite build`; no extra dependencies.

import { readFile, writeFile, mkdir } from "node:fs/promises";
import { dirname } from "node:path";
import { createServer, type ViteDevServer } from "vite";

const SITE = "https://shell-eggs.docs.potenfyr.in";

type RouteMeta = { path: string; title: string; description: string };

// ---------------------------------------------------------------- head

function jsonLd(r: RouteMeta, url: string): string {
  if (r.path !== "") {
    return JSON.stringify({
      "@context": "https://schema.org",
      "@type": "WebPage",
      name: r.title,
      description: r.description,
      url,
      isPartOf: { "@type": "WebSite", name: "Shell-Eggs", url: `${SITE}/` },
      about: {
        "@type": "SoftwareApplication",
        name: "Shell-Eggs",
        applicationCategory: "DeveloperApplication",
        operatingSystem: "Linux, Docker",
        author: { "@type": "Organization", name: "PotenFYR Studios", url: "https://potenfyr.in" },
      },
    });
  }

  // Landing: org-standard @graph.
  const org = `${SITE}/#org`;
  const website = `${SITE}/#website`;
  const app = `${SITE}/#app`;
  return JSON.stringify({
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "Organization",
        "@id": org,
        name: "PotenFYR Studios",
        url: "https://potenfyr.in",
        sameAs: ["https://github.com/PotenFYR-Studios", "https://modrinth.com/organization/potenfyr"],
      },
      {
        "@type": "WebSite",
        "@id": website,
        url: `${SITE}/`,
        name: "Shell-Eggs",
        inLanguage: "en",
        publisher: { "@id": org },
      },
      {
        "@type": "SoftwareApplication",
        "@id": app,
        name: "Shell-Eggs",
        applicationCategory: "DeveloperApplication",
        operatingSystem: "Linux, Docker",
        description:
          "Universal Pterodactyl/Pelican/Feather/Wisp/Docker egg hosting 54 shell types from one image: SSH, tunnels, reverse shells, TLS and covert channels, bind shells, web terminals and debug harnesses.",
        author: { "@id": org },
        license: "https://github.com/PotenFYR-Studios/Shell-Eggs/blob/master/LICENSE",
        codeRepository: "https://github.com/PotenFYR-Studios/Shell-Eggs",
        offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
      },
      {
        "@type": "WebPage",
        "@id": url,
        url,
        name: r.title,
        description: r.description,
        isPartOf: { "@id": website },
        about: { "@id": app },
        inLanguage: "en",
      },
    ],
  });
}

function esc(s: string): string {
  return s.replace(/"/g, "&quot;");
}

function headReplace(html: string, r: RouteMeta, url: string): string {
  const json = jsonLd(r, url);
  return html
    .replace(/<title>.*?<\/title>/, `<title>${esc(r.title)}</title>`)
    .replace(/<meta name="description" content="[^"]*" \/>/, `<meta name="description" content="${esc(r.description)}" />`)
    .replace(/<meta property="og:title" content="[^"]*" \/>/, `<meta property="og:title" content="${esc(r.title)}" />`)
    .replace(/<meta property="og:description" content="[^"]*" \/>/, `<meta property="og:description" content="${esc(r.description)}" />`)
    .replace(/<meta property="og:url" content="[^"]*" \/>/, `<meta property="og:url" content="${url}" />`)
    .replace(/<meta name="twitter:title" content="[^"]*" \/>/, `<meta name="twitter:title" content="${esc(r.title)}" />`)
    .replace(/<meta name="twitter:description" content="[^"]*" \/>/, `<meta name="twitter:description" content="${esc(r.description)}" />`)
    .replace(/<link rel="canonical" href="[^"]*" \/>/, `<link rel="canonical" href="${url}" />`)
    .replace(/<script type="application\/ld\+json">[\s\S]*?<\/script>/, () => `<script type="application/ld+json">${json}</script>`);
}

// ------------------------------------------------------- static text probe

function staticTextLen(html: string): number {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/&[a-z#0-9]+;/gi, " ")
    .replace(/\s+/g, " ")
    .trim().length;
}

// ---------------------------------------------------------------- main

let vite: ViteDevServer | undefined;
try {
  vite = await createServer({
    server: { middlewareMode: true },
    appType: "custom",
    logLevel: "error",
  });

  const ssg = (await vite.ssrLoadModule("/src/ssg-entry.tsx")) as {
    renderPage: (route: string) => string;
  };
  const site = (await vite.ssrLoadModule("/src/site.ts")) as {
    ROUTES: RouteMeta[];
    FAMILIES: unknown[];
    familyRoute: (f: unknown) => RouteMeta;
  };

  const routes: RouteMeta[] = [
    ...site.ROUTES,
    ...site.FAMILIES.map((f) => site.familyRoute(f)),
  ];

  const distDir = decodeURIComponent(new URL("../dist", import.meta.url).pathname);
  const shell = await readFile(`${distDir}/index.html`, "utf8");
  if (!shell.includes('<div id="root"></div>')) {
    throw new Error("root div placeholder not found in dist/index.html");
  }

  let minText = Number.POSITIVE_INFINITY;
  let emitted = 0;

  for (const r of routes) {
    const route = r.path === "" ? "/" : r.path;
    const url = `${SITE}${r.path === "" ? "/" : r.path}`;
    const rel = r.path === "" ? null : r.path.slice(1); // "docs/install"
    const appHtml = ssg.renderPage(route);

    let html = headReplace(shell, r, url);
    html = html.replace('<div id="root"></div>', () => `<div id="root">${appHtml}</div>`);

    if (rel === null) {
      await writeFile(`${distDir}/index.html`, html);
    } else {
      await mkdir(`${distDir}/${rel}`, { recursive: true });
      await writeFile(`${distDir}/${rel}/index.html`, html);
      await mkdir(dirname(`${distDir}/${rel}`), { recursive: true });
      await writeFile(`${distDir}/${rel}.html`, html);
      emitted += 1;
    }
    emitted += 1;

    const text = staticTextLen(html);
    minText = Math.min(minText, text);
    console.log(`[prerender] ${rel === null ? "index.html" : `${rel}.html + ${rel}/index.html`} text=${text} (${html.length} bytes)`);
  }

  console.log(`[prerender] ${emitted} files emitted for ${routes.length} routes (twins included) · min static text ${minText} chars`);
} catch (err) {
  console.error("[prerender] ERROR:", err);
  process.exitCode = 1;
} finally {
  await vite?.close();
}
