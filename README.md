# Roam Internet Guides

Static Astro site for https://roaminternetguides.com.

- Content: `src/content/guides/*.md` and `src/content/states/*.md` (bump `updated:` on monthly refreshes).
- Build & publish: `./deploy.sh` (builds and force-pushes `dist/` to `gh-pages`).

## Adding a tracking link

Every key in `src/data/links.json` becomes a redirect page `/r/<code>/` that fires the GoatCounter event `redir/<code>` and then sends the visitor to the referral URL.

1. Add an entry: `"x-pin": "Pinned post on X"` (code = lowercase letters, digits, hyphens; value = a note for yourself).
2. Commit, then run `./deploy.sh`.
3. Share `https://roaminternetguides.com/r/x-pin/`. Clicks show up in GoatCounter as `redir/x-pin`.
