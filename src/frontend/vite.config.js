import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

const host = import.meta.env.VITE_DEV_SERVER_HOST || 'localhost';

export default defineConfig(({ command }) => ({
  plugins: [react()],

  // Only set base to /static/ in production builds
  base: command === 'build' ? '/static/' : '/',

  build: {
    sourcemap: true,
    manifest: true,
    outDir: 'dist',
    rollupOptions: {
      input: 'src/index.jsx'
    }
  },

  server: {
    host: '0.0.0.0',
    port: 5173,
    strictPort: true,

    watch: {
      usePolling: true,
      interval: 100,
    },

    cors: true,

    hmr: {
      protocol: 'ws',
      host: host,
      port: 5173,
      clientPort: 5173,
    }
  }
}))