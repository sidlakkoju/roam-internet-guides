# Roam Internet Guides

Static Astro site for https://roaminternetguides.com.

- Content: `src/content/guides/*.md` and `src/content/states/*.md` (bump `updated:` on monthly refreshes).
- Build & publish: `./deploy.sh` (builds and force-pushes `dist/` to `gh-pages`).

After publishing, deploy submits the built sitemap page URLs to IndexNow using `scripts/indexnow.sh` (requires bash, curl, and python3).

## Adding a tracking link

Every key in `src/data/links.json` becomes a redirect page `/r/<code>/` that fires the GoatCounter event `redir/<code>` and then sends the visitor to the referral URL.

1. Add an entry: `"x-pin": "Pinned post on X"` (code = lowercase letters, digits, hyphens; value = a note for yourself).
2. Commit, then run `./deploy.sh`.
3. Share `https://roaminternetguides.com/r/x-pin/`. Clicks show up in GoatCounter as `redir/x-pin`.

## Referral box variants

`src/data/variants.json` defines each referral box variant's `id`, `weight`, and `enabled` flag. Weights are relative: an enabled variant with weight 2 is twice as likely to appear as one with weight 1. Disabled variants or variants with weight 0 are never shown in normal rotation. IDs must match the `data-only` markers in `src/components/ReferralBox.astro` (markers can list several IDs separated by spaces).

Preview a variant with `?force=<id>`, for example `/guides/rv/?force=steps`. This can preview disabled variants too, and does not record pageviews or referral events.

Run the report with bash, curl, and python3 installed:

```bash
./scripts/report.sh                        # 30 days ago through today
./scripts/report.sh 2026-09-01             # specified start through today
./scripts/report.sh 2026-09-01 2026-09-30  # specified date range
```

The script reads the `api_key: ...` line in `/home/box/shared/goatcounter.txt`; keep the key out of the repository. It follows API pagination and reports all configured variants, including disabled ones, sorted by open CTR, plus totals and `redir/<code>` event totals. The date range includes each full day in UTC. The `visitors` column counts unique first visits per page path, summed across pages; it is not a site-wide distinct visitor count. Open CTR is `ref-open / visitors`; any-click CTR is `(ref-open + ref-copy) / visitors`. These CTRs describe events per visitor, using GoatCounter’s unique first visits per event path rather than raw clicks: repeat clicks in the same session are excluded, and a visitor who both opens and copies counts twice in the numerator. Zero-visitor CTRs are shown as `N/A`.

Use the report to adjust `weight` and `enabled` in `variants.json`, preview the affected variants, then commit your changes and run `./deploy.sh`. The `speedtest` variant needs `public/img/speedtest.png` before enabling it.
