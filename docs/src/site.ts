// Shared site constants + shell-family doc data.
// Egg facts mirror egg-shell-multi.json / scripts/shell-registry.sh (synced by scripts/sync-data.ts).

export const BASE = "";
export const SITE_URL = "https://shell-eggs.docs.potenfyr.in";
export const REPO = "https://github.com/PotenFYR-Studios/Shell-Eggs";
export const REPO_TREE = `${REPO}/blob/master`;

export function withBase(path: string): string {
  if (path === "/") return `${BASE}/`;
  return `${BASE}${path}`;
}

export type RouteMeta = {
  path: string; // route path without base, "" for home
  title: string;
  description: string;
};

export const ROUTES: RouteMeta[] = [
  {
    path: "",
    title: "Shell-Eggs - One Egg. Every Shell. Every Direction.",
    description:
      "One universal egg hosting 54 shell types: SSH, tunnels, reverse shells, TLS and covert channels, bind shells, web terminals and debug harnesses.",
  },
  {
    path: "/docs",
    title: "Documentation Hub - Shell-Eggs",
    description:
      "Install the egg, master every startup variable and browse per-family guides for all 54 shell types, for Pterodactyl, Pelican, Feather, Wisp and Docker.",
  },
  {
    path: "/docs/install",
    title: "Install the Egg - Shell-Eggs Docs",
    description:
      "Import egg-shell-multi.json into Pterodactyl, Pelican, Feather or Wisp, or run the GHCR image with Docker. Real steps, images and startup command.",
  },
  {
    path: "/docs/variables",
    title: "Startup Variables - Shell-Eggs Docs",
    description:
      "Every egg variable from egg-shell-multi.json: SHELL_TYPE, users, passwords, extra ports, reverse targets, SSH hardening and web-shell auth.",
  },
  {
    path: "/docs/shells",
    title: "Shell Catalog - Shell-Eggs Docs",
    description:
      "Filterable catalog of all 54 shell types: server shells, multiplexers, tunnels, reverse shells, secure channels, binds, web terminals, debug.",
  },
  {
    path: "/examples",
    title: "Which Shell Mode? - Shell-Eggs Examples",
    description:
      "Chooser cards and copy-paste commands for every mode, plus ready-made listener one-liners for reverse, TLS and covert shells.",
  },
  {
    path: "/about",
    title: "About - Shell-Eggs",
    description:
      "Supported panels, what CI verifies, security and legal notes, Apache-2.0 with Commons Clause licensing - by PotenFYR Studios.",
  },
  {
    path: "/license",
    title: "License - Shell-Eggs Docs",
    description:
      "Free for any purpose, including commercial: fork, modify, self-host, redistribute. The Commons Clause only bars selling the software itself.",
  },
];

// ------------------------------------------------------------- shell families

export type Family = {
  id: string;
  slug: string;
  label: string;
  icon: string;
  accent: string; // canonical token color
  blurb: string;
  ports: string; // port policy line for the family
  listener?: string; // command you run on YOUR side first
  listenNote?: string;
};

export const FAMILIES: Family[] = [
  {
    id: "server",
    slug: "server",
    label: "Server Shells",
    icon: "🖥️",
    accent: "#8b5cf6",
    blurb:
      "SSH (standard, CA-certified, hardened keys-only), Dropbear, Telnet and Mosh listeners for managing the container.",
    ports: "Primary shell binds the panel-allocated SERVER_PORT. Mosh needs UDP 60000+.",
  },
  {
    id: "multiplexer",
    slug: "multiplexers",
    label: "Multiplexers",
    icon: "🔁",
    accent: "#ec4899",
    blurb:
      "tmux, GNU Screen and Zellij persistent sessions that survive disconnects - attach from any login shell.",
    ports: "No inbound port. Lives inside any SSH/Telnet login session.",
  },
  {
    id: "tunnel",
    slug: "tunnels",
    label: "Tunnels",
    icon: "🕳️",
    accent: "#06b6d4",
    blurb:
      "SSH -L / -R / -D forwarding, X11, rsync-over-ssh and sshfs mounts through an encrypted channel.",
    ports: "Tunnel sshd binds SERVER_PORT (default 2222 in the registry).",
  },
  {
    id: "reverse",
    slug: "reverse",
    label: "Reverse Shells",
    icon: "🎣",
    accent: "#f97316",
    blurb:
      "Interpreter and netcat-family callbacks: bash, python, PHP, perl, ruby, lua, node, powershell, go, java, groovy, awk, nc/socat and TLS flavors. Every payload reconnects forever.",
    ports: "Outbound only - no inbound port. Set SHELL_REVERSE_HOST/PORT.",
    listener: "nc -lvnp 4444",
    listenNote: "or a fully interactive PTY listener: socat file:$(tty),raw,echo=0 TCP-L:4444",
  },
  {
    id: "secure-web",
    slug: "secure-covert",
    label: "Secure / Covert",
    icon: "🛡️",
    accent: "#10b981",
    blurb:
      "TLS-wrapped shells plus websocket, DNS and ICMP channels for egress-restricted networks. TLS stops payload inspection - pin certs.",
    ports: "openssl/ncat/socat TLS callbacks use SHELL_REVERSE_PORT; wssh binds 7681; DNS/ICMP need no port.",
    listener: "socat file:$(tty),raw,echo=0 OPENSSL-LISTEN:4444,cert=server.pem,verify=0",
    listenNote: "TLS listener - generate a pair first: openssl req -x509 -newkey rsa:4096 -keyout key.pem -out server.pem -days 365 -nodes",
  },
  {
    id: "bind",
    slug: "bind-shells",
    label: "Bind Shells",
    icon: "📡",
    accent: "#facc15",
    blurb:
      "Listeners inside the container - plain nc, full-PTY socat, TLS binds and interpreter binds. You connect in.",
    ports: "Binds the primary container port (registry default 5555 unless SERVER_PORT applies).",
    listener: "nc <host> <PORT>",
    listenNote: "TLS: socat file:$(tty),raw,echo=0 OPENSSL:<host>:<PORT>,verify=0 (pin the printed fingerprint)",
  },
  {
    id: "web",
    slug: "web-terminals",
    label: "Web Terminals",
    icon: "🌐",
    accent: "#38bdf8",
    blurb:
      "Browser xterm.js terminals (ttyd, gotty) and token-authed HTTP exec shells (php/node) - a shell in a browser tab.",
    ports: "ttyd default 7681, gotty/php/node default 8080 - the first ported shell takes SERVER_PORT.",
    listener: "http://<host>:<PORT>",
    listenNote: "php/node web shells require the token: /?token=<TOKEN>&cmd=id (401 without it)",
  },
  {
    id: "debug",
    slug: "debug",
    label: "Debug Shells",
    icon: "🔬",
    accent: "#9aa0b4",
    blurb:
      "sshd -ddd auth debugging, strace-everything login shells, tcpdump capture sessions and a hex-dump socat probe relay.",
    ports: "ssh-debug binds SERVER_PORT; strace/tcpdump ride along any login; probe listens on 9000.",
  },
];

export function familyBySlug(slug: string): Family | undefined {
  return FAMILIES.find((f) => f.slug === slug);
}

// Per-family docs-route metadata (title/description) built on demand.
export function familyRoute(f: Family): RouteMeta {
  return {
    path: `/docs/shells/${f.slug}`,
    title: `${f.label} - Shell-Eggs Docs`,
    description: `Connection commands, ports and startup variables for the ${f.label} family of the universal Shell-Eggs egg.`,
  };
}

// ------------------------------------------------------------- docs shell nav

export type DocsNavItem = { path: string; label: string };
export type DocsNavGroup = { label: string; items: DocsNavItem[] };

// Sidebar grouping for the docs shell (components/DocsShell.tsx).
export const DOCS_GROUPS: DocsNavGroup[] = [
  {
    label: "Get started",
    items: [
      { path: "/docs/install", label: "Install the egg" },
      { path: "/docs/variables", label: "Startup variables" },
    ],
  },
  {
    label: "Shell families",
    items: [
      { path: "/docs/shells", label: "All shells" },
      ...FAMILIES.map((f) => ({ path: familyRoute(f).path, label: f.label })),
    ],
  },
  {
    label: "More",
    items: [
      { path: "/examples", label: "Which shell mode?" },
      { path: "/license", label: "License" },
    ],
  },
];

// Flat sidebar order; drives prev/next pagination across docs pages.
export const DOCS_ORDER: DocsNavItem[] = [
  { path: "/docs", label: "Documentation hub" },
  ...DOCS_GROUPS.flatMap((g) => g.items),
];

// ------------------------------------------------------------- egg install facts

export const EGG_JSON = `${REPO_TREE}/egg-shell-multi.json`;
export const EGGS_RAW = "https://raw.githubusercontent.com/PotenFYR-Studios/Shell-Eggs/master/egg-shell-multi.json";
export const IMAGE = "ghcr.io/potenfyr-studios/shell-eggs:latest";

export const STARTUP_CMD =
  "if [ -f /entrypoint.sh ]; then exec bash /entrypoint.sh; elif [ -f /usr/local/bin/entrypoint.sh ]; then exec bash /usr/local/bin/entrypoint.sh; elif [ -f ./entrypoint.sh ]; then exec bash ./entrypoint.sh; else curl -fsSL https://raw.githubusercontent.com/PotenFYR-Studios/Shell-Eggs/master/entrypoint.sh | exec bash; fi";

export const DOCKER_RUN = `docker run -d --name my-shells \\
  -p 2222:2222 \\
  -e SHELL_TYPE=ssh,tmux \\
  -e SHELL_USERS=alice,bob \\
  -e SHELL_PASSWORDS=auto,auto \\
  ${IMAGE}`;

export const PANEL_STEPS: { step: string; detail: string }[] = [
  {
    step: "Download the egg JSON",
    detail: `Grab egg-shell-multi.json from the repo (or let the panel pull it from the raw update_url).`,
  },
  {
    step: "Import into your nest",
    detail: "Pterodactyl/Pelican: Admin → Nests → Import Egg. Feather/Wisp: paste or upload the same JSON.",
  },
  {
    step: "Pick the Docker image",
    detail: `${IMAGE} - one universal image carries every shell type.`,
  },
  {
    step: "Allocate the primary port",
    detail: "That is all the egg needs. Extra ported shells get extra panel ports via SHELL_EXTRA_PORTS.",
  },
  {
    step: "Set the users",
    detail: "Shell Usernames = alice,bob. Leave Shell User Passwords as auto and secrets are generated for you.",
  },
  {
    step: "Start",
    detail: "SHELL_TYPE=auto (default) opens the interactive paginated picker in the console; pick any shell with your keyboard.",
  },
];

// Chooser cards for /examples: mode -> recommended SHELL_TYPE + first commands.
export type Chooser = {
  want: string;
  icon: string;
  pick: string;
  then: string;
  slug?: string;
};

export const CHOOSERS: Chooser[] = [
  {
    want: "Log in and manage the container",
    icon: "🖥️",
    pick: "ssh (or ssh-hardened for keys-only)",
    then: "ssh -p <PORT> alice@<host>",
    slug: "server",
  },
  {
    want: "Passwordless, CA-signed SSH",
    icon: "🔐",
    pick: "ssh-cert",
    then: "ssh -i mykey -o CertificateFile=mykey-cert.pub -p <PORT> alice@<host>",
    slug: "server",
  },
  {
    want: "A persistent session that survives drops",
    icon: "🔁",
    pick: "tmux (or screen / zellij)",
    then: "tmux attach -t shell-eggs",
    slug: "multiplexers",
  },
  {
    want: "Reach another host through this container",
    icon: "🕳️",
    pick: "ssh-local (-L), ssh-dynamic (-D SOCKS5)",
    then: "ssh -p <PORT> -N -L 8080:target.host:80 alice@<host>",
    slug: "tunnels",
  },
  {
    want: "Expose a container port on my machine",
    icon: "↩️",
    pick: "ssh-remote (-R)",
    then: "ssh -p <PORT> -N -R 9090:internal.host:80 alice@<host>",
    slug: "tunnels",
  },
  {
    want: "The container to call me back",
    icon: "🎣",
    pick: "python-pty (gold standard: socat)",
    then: "SHELL_REVERSE_HOST=your.ip nc -lvnp 4444   # then pick python-pty",
    slug: "reverse",
  },
  {
    want: "Encrypted callback through TLS",
    icon: "🛡️",
    pick: "openssl-rs / socat-tls / ncat-ssl",
    then: "socat file:$(tty),raw,echo=0 OPENSSL-LISTEN:4444,cert=server.pem,verify=0",
    slug: "secure-covert",
  },
  {
    want: "A shell that looks like web traffic",
    icon: "🕸️",
    pick: "wssh (websocket) or ttyd (browser)",
    then: "browser → http://<host>:7681",
    slug: "web-terminals",
  },
  {
    want: "Someone connects in to me",
    icon: "📡",
    pick: "socat-bind (PTY) or openssl-bind (TLS)",
    then: "nc <host> <PORT>",
    slug: "bind-shells",
  },
  {
    want: "Debug SSH auth or trace a session",
    icon: "🔬",
    pick: "ssh-debug, strace-shell, tcpdump-shell",
    then: "ssh -p <PORT> -vvv alice@<host>   # while sshd -ddd streams to console",
    slug: "debug",
  },
];
