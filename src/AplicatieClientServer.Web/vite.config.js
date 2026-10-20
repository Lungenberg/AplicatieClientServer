import { defineConfig, loadEnv } from "vite";

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "");

  return {
    server: {
      host: "localhost",
      port: 5173,
      strictPort: true,
      proxy: {
        "^/api(?:/|$)": {
          target: env.API_PROXY_TARGET || "http://localhost:5050",
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/api/, ""),
        },
      },
    },
    preview: {
      host: "localhost",
      port: 4173,
      strictPort: true,
    },
  };
});
