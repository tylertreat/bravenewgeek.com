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

echo "postbuild: WordPress-compat shims applied"
