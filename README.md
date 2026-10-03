# firproject.org

Static landing page for [FIR](https://firproject.org) — *Free. Independent. Reproducible.*

Plain HTML + CSS. No frameworks, no build step, no JavaScript. Keeps with the project's
philosophy.

## Preview locally

```sh
python3 -m http.server 8080
# open http://localhost:8080
```

## Deploy

1. Push this directory to `github.com/firproject/firproject.org`
   (or serve it from any static host — it's two files).
2. Enable GitHub Pages on the repo (main branch, root).
3. After the domain is purchased: Settings → Pages → Custom domain → `firproject.org`,
   which adds a `CNAME` file. Add an `A` record pointing at GitHub's IPs per docs.github.com.

## Editing

- Copy lives in `index.html` — sections are commented.
- Colours/spacing are CSS variables at the top of `style.css`.
- News entries: add `<li>` blocks in the Status section (template in an HTML comment).
