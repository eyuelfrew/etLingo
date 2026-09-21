import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const port = Number(env.VITE_PORT || 5173);
  // Prefer explicit API URL; otherwise proxy /api → backend so the console always talks to :5050.
  const apiTarget = env.VITE_API_URL?.replace(/\/api\/v\d+\/?$/, '') || 'http://localhost:5050';

  return {
    plugins: [react(), tailwindcss()],
    server: {
      port,
      proxy: {
        '/api': {
          target: apiTarget,
          changeOrigin: true,
        },
        '/audio': {
          target: apiTarget,
          changeOrigin: true,
        },
      },
    },
  };
});
