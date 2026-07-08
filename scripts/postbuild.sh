#!/usr/bin/env bash
# WordPress-compat output shims, run after `hugo`. GitHub Pages can't issue
# redirects, so legacy WP paths are satisfied with file copies. The /feed/
# copies are named index.html (Pages serves directory indexes only for that
# name); they contain RSS XML, which feed readers content-sniff.
set -euo pipefail
cd "$(dirname "$0")/.."

# Main feed: WP served it at /feed/ (and some readers use /feed.xml).
cp public/index.xml public/feed.xml
mkdir -p public/feed
cp public/index.xml public/feed/index.html

# Author feed mirrors the main feed (single-author blog).
mkdir -p public/author/tyler/feed
cp public/index.xml public/author/tyler/feed/index.html

# Category/tag feeds: Hugo emits term RSS at <term>/index.xml; WP served it
# at <term>/feed/.
for d in public/category/*/ public/tag/*/; do
  [ -f "${d}index.xml" ] || continue
  mkdir -p "${d}feed"
  cp "${d}index.xml" "${d}feed/index.html"
done

# WordPress core sitemap names, so crawlers with the old URLs stay happy.
for f in wp-sitemap.xml wp-sitemap-posts-post-1.xml wp-sitemap-posts-page-1.xml \
         wp-sitemap-taxonomies-category-1.xml wp-sitemap-users-1.xml; do
  cp public/sitemap.xml "public/$f"
done

# Home pagination used to be 5/page (WordPress: /page/2/../page/23/). The home
# feed is now 20/page, so the high-numbered pages no longer exist. Redirect each
# orphaned old page to the new page holding its first post, so no URL 404s.
# old first-post index (0-based) = (N-1)*5; new page = floor(index/20)+1.
for N in $(seq 2 23); do
  [ -d "public/page/$N" ] && continue   # still a real page under the new size
  target=$(( ((N-1)*5) / 20 + 1 ))
  if [ "$target" -le 1 ]; then dest="/"; else dest="/page/$target/"; fi
  mkdir -p "public/page/$N"
  cat > "public/page/$N/index.html" <<HTML
<!doctype html><html><head><meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=$dest">
<link rel="canonical" href="$dest"><title>Redirecting…</title>
</head><body><a href="$dest">Continue to the log</a></body></html>
HTML
done

echo "postbuild: WordPress-compat shims applied"
