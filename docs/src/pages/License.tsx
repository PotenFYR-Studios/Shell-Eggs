import { DocsShell, type TocItem } from "../components/DocsShell";
import { REPO_TREE } from "../site";

const LICENSE_URL = `${REPO_TREE}/LICENSE`;

// Minimal redistribution notice. The LICENSE file carries no explicit
// copyright year line, so the notice omits one rather than inventing it.
const NOTICE = `Shell-Eggs. Copyright PotenFYR Studios.
Licensed under the Apache License, Version 2.0 with the Commons Clause
License Condition v1.0. The full license text lives in the LICENSE file:
https://github.com/PotenFYR-Studios/Shell-Eggs/blob/master/LICENSE.`;

const TOC: TocItem[] = [
  { id: "short-version", label: "The short version" },
  { id: "you-can", label: "What you can do" },
  { id: "you-cant", label: "What you can't do" },
  { id: "attribution", label: "Attribution" },
  { id: "full-text", label: "The full text" },
];

export default function License({ route }: { route: string }) {
  return (
    <DocsShell route={route} crumbs={[{ label: "Docs", to: "/docs" }, { label: "License" }]} toc={TOC}>
      <p className="eyebrow">Shell-Eggs Docs · Legal</p>
      <h1 className="grad-text mt-6 text-4xl font-extrabold tracking-tight">License</h1>
      <p className="mt-4" style={{ color: "var(--muted)" }}>
        Shell-Eggs is free to use, change and share, with one clear rule about selling the software itself. This
        page is the plain-English summary; the{" "}
        <a href={LICENSE_URL} target="_blank" rel="noopener">
          LICENSE file
        </a>{" "}
        in the repository is the authoritative text and always wins over any summary.
      </p>

      <h2 className="doc-h2" id="short-version">
        The short version
      </h2>
      <p className="text-sm leading-relaxed" style={{ color: "var(--text-2)" }}>
        Shell-Eggs is licensed under the <strong>Apache License 2.0</strong> with the{" "}
        <strong>Commons Clause License Condition v1.0</strong>. Everything is permitted except one thing: you may
        not sell the egg itself, and you may not build a paid product whose value is essentially just the
        software's functionality.
      </p>

      <h2 className="doc-h2" id="you-can">
        What you can do
      </h2>
      <ul className="space-y-2 text-sm" style={{ color: "var(--text-2)" }}>
        <li>
          <strong>Fork it</strong> and modify it freely, for any purpose.
        </li>
        <li>
          <strong>Use it commercially</strong>: run it for a business, for clients or for a community.
        </li>
        <li>
          <strong>Self-host</strong> it on your own servers and panels, with no limits on scale.
        </li>
        <li>
          <strong>Redistribute</strong> it, in original or modified form.
        </li>
        <li>
          <strong>Build products or services around it</strong>: hosting, setup, managed panels, support and
          consulting are all fine, because your value comes from your service, not from selling the software.
        </li>
      </ul>

      <h2 className="doc-h2" id="you-cant">
        What you can't do
      </h2>
      <ul className="space-y-2 text-sm" style={{ color: "var(--text-2)" }}>
        <li>
          <strong>Sell the software itself.</strong> Shell-Eggs may not be marketed or sold as a product.
        </li>
        <li>
          <strong>Sell its functionality.</strong> A paid product or service whose value derives entirely or
          substantially from the software's functionality is off limits.
        </li>
        <li>
          <strong>Use PotenFYR names or trademarks.</strong> Do not brand your fork or service with PotenFYR or
          Shell-Eggs names or logos, or imply endorsement.
        </li>
      </ul>

      <h2 className="doc-h2" id="attribution">
        Attribution
      </h2>
      <p className="text-sm leading-relaxed" style={{ color: "var(--text-2)" }}>
        If you redistribute Shell-Eggs, keep the license notices with the source, including the Commons Clause
        text. A minimal notice looks like this:
      </p>
      <pre className="mt-3" data-lang="text">
        <code>{NOTICE}</code>
      </pre>

      <h2 className="doc-h2" id="full-text">
        The full text
      </h2>
      <p className="text-sm leading-relaxed" style={{ color: "var(--text-2)" }}>
        Read the complete license in the{" "}
        <a href={LICENSE_URL} target="_blank" rel="noopener">
          LICENSE file on GitHub
        </a>
        . Questions about what is allowed? Open an issue or write to{" "}
        <a href="mailto:support@potenfyr.in">support@potenfyr.in</a>.
      </p>
    </DocsShell>
  );
}
