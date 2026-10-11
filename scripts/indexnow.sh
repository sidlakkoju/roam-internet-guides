#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
payload="$(python3 - "$repo_root" <<'PY'
import json
import pathlib
import re
import sys
import xml.etree.ElementTree as ET

repo_root = pathlib.Path(sys.argv[1])
key_files = sorted(
    path for path in (repo_root / "public").glob("*.txt")
    if path.is_file() and re.fullmatch(r"[0-9a-f]{32}\.txt", path.name)
)
if len(key_files) != 1:
    sys.exit("indexnow: expected exactly one public/[0-9a-f]{32}.txt key file")
key = key_files[0].stem
urls = []
for sitemap in sorted((repo_root / "dist").glob("sitemap-*.xml")):
    root = ET.parse(sitemap).getroot()
    if root.tag.rsplit("}", 1)[-1] != "urlset":
        continue
    for element in root.iter():
        if element.tag.rsplit("}", 1)[-1] == "loc" and element.text:
            url = element.text.strip()
            if url:
                urls.append(url)
if not urls:
    sys.exit("indexnow: built sitemaps contain no page URLs; run npm run build first")
print(json.dumps({
    "host": "roaminternetguides.com",
    "key": key,
    "keyLocation": f"https://roaminternetguides.com/{key}.txt",
    "urlList": urls,
}))
PY
)"

curl --silent --show-error --fail \
    --connect-timeout 15 --max-time 60 \
    --request POST \
    --header 'Content-Type: application/json' \
    --data-binary "$payload" \
    --output /dev/null --write-out '%{http_code}\n' \
    https://api.indexnow.org/indexnow
