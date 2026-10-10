#!/usr/bin/env bash
# Build and publish dist/ to the gh-pages branch (used until the Actions workflow can be pushed).
set -euo pipefail
cd "$(dirname "$0")"
npm run build
touch dist/.nojekyll
cd dist && git init -q -b gh-pages && git add -A && git commit -qm "Deploy $(date -u +%FT%TZ)" && git push -f "$(cd .. && git remote get-url origin)" gh-pages && rm -rf .git
