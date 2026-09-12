import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

// Custom-domain root: https://shell-eggs.docs.potenfyr.in/
export default defineConfig({
  base: "/",
  plugins: [react(), tailwindcss()],
  build: {
    outDir: "dist",
    sourcemap: false,
  },
});
