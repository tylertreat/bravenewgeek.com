# bravenewgeek.com

Static Hugo site for [Brave New Geek](https://bravenewgeek.com), migrated from
WordPress (HostGator) in July 2026. Hosted on GitHub Pages; every push to
`main` triggers a build and deploy via GitHub Actions.

## Writing a new post

```sh
hugo new content/posts/my-new-post.md
# edit, then set draft: false (or remove it) and:
git add . && git commit -m "New post" && git push
```

Front matter follows the existing posts: `title`, `date`, `slug`,
`categories`, `tags`. The permalink is `https://bravenewgeek.com/<slug>/`.

## Local preview

```sh
hugo server -D   # http://localhost:1313
```

## Layout notes

- `content/posts/` — all posts, one markdown file per post, converted from
  the WordPress REST API export.
- `content/categories/`, `content/tags/` — term stubs that pin taxonomy
  archive URLs to their historical WordPress slugs (e.g. `/category/go-2/`).
  Don't delete these; inbound links depend on them.
- `data/comments/` — WordPress-era comments, frozen and rendered read-only
  by `layouts/partials/comments.html`.
- `static/wp-content/uploads/` — the migrated WordPress media library, kept
  at the same paths so old image URLs still resolve.
- `layouts/home.rss.xml` — full-content RSS at `/index.xml`; the deploy
  workflow also copies it to `/feed/` and `/feed.xml` for legacy WordPress
  subscribers.
- `themes/PaperMod/` — vendored (not a submodule); update by re-cloning from
  https://github.com/adityatelange/hugo-PaperMod when desired.
