import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
// When a custom domain is added, set SITE to it and BASE to '/'.
export default defineConfig({
  site: process.env.SITE || 'https://sidlakkoju.github.io',
  base: process.env.BASE || '/roam-internet-guides',
  trailingSlash: 'always',
  integrations: [sitemap({ filter: (p) => !p.includes('/r/') })],
});
