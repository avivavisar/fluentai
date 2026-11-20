# תאילנד 2026 – המהדורה הפרטית

The Thailand 2026 travel companion (Aviv & Ofek, 25.11–20.12.2026). It runs as a claude.ai artifact.
Its data lives in the artifact's shared database (`items/*`, `chat/log`, `notes/*`, `photos/*`), not in this repo.

| Path | What |
|---|---|
| `app/index.html` | The app (single file, vanilla JS, Hebrew RTL). Published as the artifact page. |
| `app/geo.json` | Map coastlines: OpenStreetMap-derived land polygons (via `@geo-maps/countries-land-100m`), clipped and simplified per trip region. © OpenStreetMap contributors. |
| `backup/live-page-2026-11-20/index.html` | Exact copy of the live page before the redesign. |
| `backup/items-2026-11-20/` | Snapshot of all 47 database items before the redesign. |
| `backup/research-doc-2026-11-20.json` | Snapshot of the research doc (Claude Docs XML). |
| `seed/items-preview.json` | Data seeded into the preview artifact: the 47 items plus optional `lat`/`lng` (approximate) and `date`/`time` where the item's own text named a single day. |

Artifacts:
- Live: https://claude.ai/artifact/32DF3vSdNT5ko6eKsaDi4J (original page, untouched)
- Preview of the redesign: https://claude.ai/artifact/SbL5qXjkU29BLc6G31NstR (own database, seeded copy)

Data contract: every original field (`name dest cat tag score when cost dist note link status mine order updatedAt`)
keeps its meaning. The redesign only adds optional fields: `kind date time dayOrder fav rating memory doneAt lat lng place ref`.
