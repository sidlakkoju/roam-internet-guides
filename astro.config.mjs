import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
// When a custom domain is added, set SITE to it and BASE to '/'.
export default defineConfig({
  site: process.env.SITE || 'https://roaminternetguides.com',
  base: process.env.BASE || '/',
  trailingSlash: 'always',
  integrations: [sitemap({ filter: (p) => !p.includes('/r/') })],
});
