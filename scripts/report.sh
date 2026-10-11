#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
exec python3 - "$repo_root" "$@" <<'PY'
import datetime as dt
import json
import pathlib
import re
import subprocess
import sys
import time
from collections import Counter
from urllib.parse import parse_qs, urlencode, urlsplit


def fail(message):
    print(f"report: {message}", file=sys.stderr)
    sys.exit(1)


def main():
    args = sys.argv[2:]
    if len(args) > 2:
        fail("usage: scripts/report.sh [start YYYY-MM-DD] [end YYYY-MM-DD]")
    today = dt.date.today()
    dates = [str(today - dt.timedelta(days=30)), str(today)]
    for i, value in enumerate(args):
        if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", value):
            fail("dates must use YYYY-MM-DD")
        try:
            dt.date.fromisoformat(value)
        except ValueError:
            fail("invalid calendar date")
        dates[i] = value
    if dates[0] > dates[1]:
        fail("start date must be on or before end date")

    variants = json.loads((pathlib.Path(sys.argv[1]) / "src/data/variants.json").read_text())
    counts = {variant["id"]: [0, 0, 0] for variant in variants}
    credentials = pathlib.Path("/home/box/shared/goatcounter.txt").read_text()
    match = re.search(r"^api_key:[ \t]*(\S+)[ \t]*$", credentials, re.MULTILINE)
    if not match:
        fail("missing api_key in /home/box/shared/goatcounter.txt")
    key = match.group(1).replace("\\", "\\\\").replace('"', '\\"')
    config = f'header = "Authorization: Bearer {key}"\n'
    redirects = Counter()
    seen = set()
    while True:
        params = {"start": dates[0] + "T00:00:00Z",
                  "end": dates[1] + "T23:59:59Z", "limit": 100}
        if seen:
            params["exclude_paths"] = ",".join(map(str, sorted(seen)))
        url = "https://roaminternet.goatcounter.com/api/v0/stats/hits?" + urlencode(params)
        result = subprocess.run(
            ["curl", "--disable", "--silent", "--show-error", "--fail",
             "--connect-timeout", "15", "--max-time", "60",
             "--header", "Content-Type: application/json", "--config", "-", url],
            input=config, text=True, capture_output=True,
        )
        if result.returncode:
            fail(f"GoatCounter request failed (curl exit {result.returncode})")
        try:
            data = json.loads(result.stdout)
        except ValueError:
            fail("GoatCounter returned invalid JSON")
        if not isinstance(data, dict) or not isinstance(data.get("hits"), list):
            fail("unexpected GoatCounter response (expected hits list)")
        previous_size = len(seen)
        for hit in data["hits"]:
            path_id = int(hit["path_id"])
            if path_id in seen:
                continue
            seen.add(path_id)
            path, count = hit["path"], int(hit["count"])
            if hit["event"]:
                if path.startswith("redir/"):
                    redirects[path] += count
                else:
                    kind, separator, rest = path.partition("/")
                    page, separator2, variant = rest.rpartition("/")
                    if (separator and separator2 and page and variant in counts
                            and kind in ("ref-open", "ref-copy")):
                        counts[variant][1 if kind == "ref-open" else 2] += count
            else:
                variant = parse_qs(urlsplit(path).query).get("v", [None])[0]
                if variant in counts:
                    counts[variant][0] += count
        if not data.get("more", False):
            break
        if len(seen) == previous_size:
            fail("pagination made no progress")
        time.sleep(0.3)

    def ctr(events, visitors):
        return f"{events / visitors:.2%}" if visitors else "N/A"

    def row(variant, enabled, weight, values):
        visitors, opened, copied = values
        return [variant, enabled, str(weight), str(visitors), str(opened), str(copied),
                ctr(opened, visitors), ctr(opened + copied, visitors)]

    rows = [["variant", "enabled", "weight", "visitors", "ref-open", "ref-copy",
             "open CTR", "any-click CTR"]]
    ordered = sorted(variants, key=lambda v: (
        -(counts[v["id"]][1] / counts[v["id"]][0]) if counts[v["id"]][0] else float("inf"),
        v["id"],
    ))
    for variant in ordered:
        rows.append(row(variant["id"], str(variant["enabled"]).lower(),
                        variant["weight"], counts[variant["id"]]))
    totals = [sum(values[i] for values in counts.values()) for i in range(3)]
    rows.append(row("TOTAL", "-", "-", totals))
    widths = [max(len(r[i]) for r in rows) for i in range(len(rows[0]))]
    print(f"Referral box variants: {dates[0]} to {dates[1]} (open CTR descending)")
    for r in rows:
        print("  ".join(value.ljust(width) for value, width in zip(r, widths)))
    print("\nN/A = zero visitors. TOTAL includes only IDs in variants.json.")
    print("Visitors = unique first visits per path, summed across pages.")
    print("CTRs = events per visitor; event counts are unique first visits per event path.")
    print("Repeat clicks in a session are excluded; open + copy counts a visitor twice.")
    print("\nRedirect events:")
    for path, count in sorted(redirects.items()):
        print(f"{path}  {count}")
    print(f"TOTAL  {sum(redirects.values())}")


try:
    main()
except (OSError, ValueError, KeyError, TypeError):
    fail("unable to read credentials/variants or process API data")
PY
