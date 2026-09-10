import { useEffect, useState } from "react";
import { motion, useInView, useSpring, useTransform } from "framer-motion";
import { useRef } from "react";

/* ---------------------------------- hooks --------------------------------- */

export function useTypewriter(words: string[], speed = 65, pause = 1500) {
  const [text, setText] = useState("");
  // Identity-safe: callers may pass inline arrays; we must not restart the
  // effect on every render or the typewriter never progresses ("stuck at ss").
  const wordsRef = useRef(words);
  wordsRef.current = words;
  const state = useRef({ word: 0, i: 0, deleting: false });
  const [wordIdx, setWordIdx] = useState(0);
  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    const tick = () => {
      const s = state.current;
      const target = wordsRef.current[s.word % wordsRef.current.length] ?? "";
      if (!s.deleting) {
        s.i++;
        setText(target.slice(0, s.i));
        if (s.i >= target.length && target.length > 0) {
          s.deleting = true;
          timer = setTimeout(tick, pause);
          return;
        }
      } else {
        s.i--;
        setText(target.slice(0, s.i));
        if (s.i <= 0) {
          s.deleting = false;
          s.word = (s.word + 1) % Math.max(wordsRef.current.length, 1);
          setWordIdx(s.word);
        }
      }
      timer = setTimeout(tick, s.deleting ? speed / 2 : speed);
    };
    timer = setTimeout(tick, 300);
    return () => clearTimeout(timer);
  }, [wordIdx, speed, pause]);
  return text;
}

/* --------------------------------- ticker --------------------------------- */

export function NumberTicker({ value, className }: { value: number; className?: string }) {
  const ref = useRef<HTMLSpanElement>(null);
  const inView = useInView(ref, { once: true, margin: "-40px" });
  const spring = useSpring(0, { damping: 30, stiffness: 120 });
  const display = useTransform(spring, (v) => Math.round(v).toString());
  useEffect(() => {
    if (inView) spring.set(value);
  }, [inView, value, spring]);
  return (
    <span ref={ref} className={className}>
      <motion.span className="ticker">{display}</motion.span>
    </span>
  );
}

/* ------------------------------ magic effects ------------------------------ */

export function AuroraBackdrop() {
  return (
    <>
      <div className="aurora" aria-hidden />
      <div className="grid-overlay" aria-hidden />
    </>
  );
}

export function BeamCard({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  return <div className={`beam-card ${className}`}>{children}</div>;
}

export function FadeIn({
  children,
  delay = 0,
  y = 24,
  className = "",
}: {
  children: React.ReactNode;
  delay?: number;
  y?: number;
  className?: string;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-60px" }}
      transition={{ duration: 0.7, delay, ease: [0.21, 0.65, 0.35, 1] }}
      className={className}
    >
      {children}
    </motion.div>
  );
}

export function ShimmerButton({ children, href }: { children: React.ReactNode; href: string }) {
  return (
    <a
      href={href}
      className="group relative inline-flex items-center gap-2 overflow-hidden rounded-xl px-6 py-3 text-sm font-semibold text-slate-950 transition-transform hover:scale-[1.03] active:scale-[0.98]"
      style={{ background: "linear-gradient(110deg, #22d3ee, #a78bfa 45%, #f472b6)" }}
    >
      <span className="absolute inset-0 -translate-x-full bg-white/30 blur-md transition-transform duration-700 group-hover:translate-x-full" />
      <span className="relative">{children}</span>
    </a>
  );
}

/* ------------------------------ boot terminal ----------------------------- */

const BOOT_LINES = [
  "$ SHELL_TYPE=auto bash /entrypoint.sh",
  "</> shell-eggs  Detected panel: Pterodactyl/Pelican",
  "</> shell-eggs  SHELL-TYPE is set to AUTO - opening picker",
  "  +==========================================================+",
  "  |  SHELL-EGGS INTERACTIVE PICKER - choose your shell        |",
  "  +==========================================================+",
  "  How do you want to reach this container?",
  "   1) Server / incoming   - SSH, Dropbear, Telnet, Mosh",
  "   2) Multiplexer         - tmux / screen / zellij",
  "   3) Reverse shell       - container calls back to you",
  "   4) Browse everything   - page through the full catalog",
  "</> shell-eggs  SSH ready on port 2222 (users: alice bob)",
  "</> shell-eggs  Supervisor online. Managed services: ssh",
];

export function BootTerminal() {
  const [lines, setLines] = useState<string[]>([]);
  const [done, setDone] = useState(false);
  useEffect(() => {
    let i = 0;
    const t = setInterval(() => {
      i++;
      setLines(BOOT_LINES.slice(0, i));
      if (i >= BOOT_LINES.length) {
        clearInterval(t);
        setDone(true);
      }
    }, 420);
    return () => clearInterval(t);
  }, []);
  // After boot completes, animate a typed secondary command instead of a
  // blinking idle caret (same "stuck" feel we fixed in the typewriter).
  const tail = useTypewriter(
    ["ss -tlpn | grep sshd", "tmux attach -t shell-eggs", "cat .sh-users/credentials"],
    55,
    2200,
  );
  return (
    <BeamCard className="p-0">
      <div className="flex items-center gap-2 border-b border-slate-700/40 px-4 py-3">
        <span className="h-3 w-3 rounded-full bg-rose-400/80" />
        <span className="h-3 w-3 rounded-full bg-amber-300/80" />
        <span className="h-3 w-3 rounded-full bg-emerald-400/80" />
        <span className="ml-3 text-xs text-slate-400">container console</span>
      </div>
      <pre className="min-h-[320px] overflow-x-auto p-5 text-[12.5px] leading-6 text-slate-300">
        {lines.map((l, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, x: -8 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.25 }}
            className={l.startsWith("</>") ? "text-cyan-300" : l.startsWith("$") ? "text-fuchsia-300" : ""}
          >
            {l}
          </motion.div>
        ))}
        {done && (
          <div className="text-fuchsia-300">
            $ {tail}
            <span className="caret" />
          </div>
        )}
        {!done && <span className="caret" />}
      </pre>
    </BeamCard>
  );
}
