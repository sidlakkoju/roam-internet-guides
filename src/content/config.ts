import { defineCollection, z } from 'astro:content';
const faq = z.array(z.object({ q: z.string(), a: z.string() })).default([]);
const page = z.object({
  title: z.string(),            // <title>; keep brand name out
  description: z.string(),
  heading: z.string(),
  updated: z.string(),          // YYYY-MM, bump on monthly refresh
  order: z.number().default(100),
  faq,
});
export const collections = {
  guides: defineCollection({ type: 'content', schema: page }),
  states: defineCollection({ type: 'content', schema: page.extend({ state: z.string() }) }),
};
