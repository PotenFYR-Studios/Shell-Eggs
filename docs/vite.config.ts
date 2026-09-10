import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

// GitHub Pages project-site base: https://potenfyr-studios.github.io/Shell-Eggs/
export default defineConfig({
  base: "/Shell-Eggs/",
  plugins: [react(), tailwindcss()],
  build: {
    outDir: "dist",
    sourcemap: false,
  },
});
