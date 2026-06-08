# Agent Skills Harness — docs site

[Nextra](https://nextra.site) (Next.js App Router) docs + landing site for the harness. The documentation
pages are **not authored here** — they are synced from the repo's canonical markdown (`docs/`, the benchmark,
the factory's best-practices reference) at build time, so the site can't drift from the source.

## Local development

```bash
cd site
npm install
npm run dev        # runs scripts/sync-docs.mjs, then next dev
```

Open http://localhost:3000.

- `npm run sync` — regenerate `content/docs/*.md` from the canonical sources (also runs automatically before `dev`/`build`).
- `npm run build` — production build (runs the sync first).

## What's authored vs generated

| Authored (committed) | Generated (gitignored) |
|----------------------|------------------------|
| `content/index.mdx` (landing) | `content/docs/*.md` (synced from repo docs) |
| `content/_meta.js`, `content/docs/_meta.js` (nav) | |
| `content/docs/index.mdx` (docs overview) | |
| `scripts/sync-docs.mjs`, app/config | |

To change a docs page, edit its **source** in the repo (e.g. `docs/reference/io-contract.md`) — never the
generated copy. To change which docs are published or their order, edit `scripts/sync-docs.mjs` and
`content/docs/_meta.js`.

## Deploy (Vercel)

Connect `a-tokyo/agent-skills-harness` as a Vercel project with:

- **Root Directory:** `site`
- **Framework Preset:** Next.js
- **Build Command:** `npm run build` (the `prebuild` hook runs the doc sync)
- **Install Command:** `npm install`

Auto-deploys on push to `main`. No env vars required.
