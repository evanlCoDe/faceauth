import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react()],
  define: {
    "process.env.NODE_ENV": JSON.stringify("production"),
  },
  build: {
    lib: {
      entry: "liquid-glass-logo-entry.tsx",
      formats: ["es"],
      fileName: "liquid-glass-logo",
      cssFileName: "liquid-glass-logo",
    },
    outDir: "generated",
    emptyOutDir: true,
    cssCodeSplit: false,
  },
});
