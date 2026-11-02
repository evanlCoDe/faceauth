import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react()],
  define: {
    "process.env.NODE_ENV": JSON.stringify("production"),
  },
  build: {
    lib: {
      entry: "soap-bubble-settings-entry.tsx",
      formats: ["es"],
      fileName: "soap-bubble-settings",
      cssFileName: "soap-bubble-settings",
    },
    outDir: "generated",
    emptyOutDir: false,
    cssCodeSplit: false,
  },
});
