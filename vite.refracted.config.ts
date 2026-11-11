import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react()],
  define: {
    "process.env.NODE_ENV": JSON.stringify("production"),
  },
  build: {
    lib: {
      entry: "faceid-refracted-text-entry.tsx",
      formats: ["es"],
      fileName: "faceid-refracted-text",
      cssFileName: "faceid-refracted-text",
    },
    outDir: "generated",
    emptyOutDir: false,
    cssCodeSplit: false,
  },
});
