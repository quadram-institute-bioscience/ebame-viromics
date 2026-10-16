#!/usr/bin/env python3
"""
make-table-page.py — turn a TSV/CSV file into a standalone, searchable,
sortable HTML page using ``standalone-tsv-template.html``.

The result is ONE self-contained file: the table data is embedded in the
page, so it works offline and can be copied anywhere (no server, no CDN).

Examples
--------
    ./make-table-page.py human_gut_assembly_taxonomy.tsv \
        --title "geNomad annotation: taxonomy"

    ./make-table-page.py genes.csv --title "Genes" --page-size 100 \
        --columns '{"start": {"type": "number"}, "contig": {"hidden": true}}'

    ./make-table-page.py big.tsv --title "Big" --max-rows 5000

The data block and the config block of the template are the only things
rewritten; everything else is copied verbatim.
"""

import argparse
import json
import os
import re
import sys
from html import escape

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_TEMPLATE = os.path.join(HERE, "standalone-tsv-template.html")

# Anchor on the real blocks (line-start + exact indentation). The top-of-file
# comment also mentions these tags, so a bare search would match the comment.
DATA_RE = re.compile(
    r'^  <script id="tsv-data" type="text/plain">[\s\S]*?</script>',
    re.M,
)
CFG_RE = re.compile(
    r'^  <script>\n    window\.TSV_TABLE_CONFIG =[\s\S]*?\n  </script>',
    re.M,
)

# Static metadata / hero text, so the page is meaningful before JS runs too.
TITLE_RE = re.compile(r"<title>.*?</title>", re.S)
DESC_RE = re.compile(r'<meta name="description" content="[^"]*">')
H1_RE = re.compile(r'(<h1 id="page-title">)[^<]*(</h1>)')
LEAD_RE = re.compile(r'(<p class="lead" id="page-subtitle">)[^<]*(</p>)')
CAP_RE = re.compile(r'(<p class="table-caption" id="table-caption"[^>]*?)hidden([^>]*>)[^<]*(</p>)')
INTRO_RE = re.compile(r'<section class="intro" id="intro"[^>]*></section>')


def parse_bool(value):
    return {"true": True, "false": False}.get(value.lower(), value.lower())


def build_config(args, columns, page_sizes):
    return {
        "title": args.title,
        "subtitle": args.subtitle,
        "caption": args.caption,
        # parsing
        "delimiter": args.delimiter,
        "header": parse_bool(args.header),
        "source": "",
        "data": None,  # null -> read the inline #tsv-data block
        # view
        "pageSize": args.page_size,
        "pageSizes": page_sizes,
        "search": True,
        "filters": True,
        "columnToggle": True,
        "exportButton": True,
        "rowNumbers": True,
        "stickyHeader": True,
        "hero": True,
        # hints
        "columns": columns,
    }


def render_config_block(config):
    body = json.dumps(config, indent=2, ensure_ascii=False)
    body = "\n".join("    " + line for line in body.splitlines())
    return "  <script>\n    window.TSV_TABLE_CONFIG = " + body.lstrip() + ";\n  </script>"


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("data", help="input .tsv / .csv / .txt file")
    ap.add_argument("--title", default="Data table")
    ap.add_argument("--subtitle", default="")
    ap.add_argument("--caption", default="")
    ap.add_argument("--intro", default="", help="HTML explanation shown above the table")
    ap.add_argument("--intro-file", help="read the --intro HTML from this file")
    ap.add_argument("--template", default=DEFAULT_TEMPLATE)
    ap.add_argument("--out", help="output HTML path (default: input name with .html)")
    ap.add_argument("--page-size", type=int, default=50)
    ap.add_argument("--page-sizes", default="25,50,100,250,0",
                    help="comma-separated options; 0 means 'All'")
    ap.add_argument("--delimiter", default="auto",
                    help='"auto", "\\t", ",", ";", "|"')
    ap.add_argument("--header", default="true", choices=["true", "false", "auto"])
    ap.add_argument("--max-rows", type=int, default=0,
                    help="keep only the first N data rows (0 = keep all)")
    ap.add_argument("--columns", default="{}",
                    help="JSON object of per-column hints, e.g. '{\"chr\": {\"hidden\": true}}'")
    args = ap.parse_args()

    with open(args.template, encoding="utf-8") as fh:
        html = fh.read()

    with open(args.data, encoding="utf-8", newline="") as fh:
        raw = fh.read().replace("\r\n", "\n").replace("\r", "\n")

    lines = raw.split("\n")
    header_line, body_lines = lines[0], [l for l in lines[1:] if l != ""]
    total = len(body_lines)

    truncated = False
    if args.max_rows and 0 < args.max_rows < total:
        body_lines = body_lines[: args.max_rows]
        truncated = True

    kept = len(body_lines)
    raw = "\n".join([header_line] + body_lines)
    if not raw.endswith("\n"):
        raw += "\n"

    # The only sequence that can end a <script> element early.
    safe = re.sub(r"</script", r"<\\/script", raw, flags=re.I)

    try:
        columns = json.loads(args.columns) if args.columns else {}
    except json.JSONDecodeError as exc:
        sys.exit("Invalid --columns JSON: " + str(exc))

    page_sizes = [int(x) for x in str(args.page_sizes).split(",") if x.strip() != ""]

    caption = args.caption
    note = "Source: %s — %s rows" % (os.path.basename(args.data), f"{kept:,}")
    if truncated:
        note += " (truncated from %s)" % f"{total:,}"
    caption = (caption + " · " if caption else "") + note

    config = build_config(args, columns, page_sizes)
    config["caption"] = caption
    if args.page_size not in page_sizes:
        config["pageSizes"] = sorted(set(page_sizes + [args.page_size]))

    data_block = '  <script id="tsv-data" type="text/plain">' + safe + "</script>"

    html, n_data = DATA_RE.subn(lambda _m: data_block, html, count=1)
    html, n_cfg = CFG_RE.subn(lambda _m: render_config_block(config), html, count=1)
    if n_data != 1 or n_cfg != 1:
        sys.exit("Could not locate template blocks (found data=%d, config=%d). "
                 "Is --template a standalone-tsv-template.html?" % (n_data, n_cfg))

    # Static metadata + hero text, so the page reads correctly before JS runs.
    description = args.subtitle or (args.title + " — searchable, sortable data table.")
    html = TITLE_RE.sub(lambda _m: "<title>%s · Viromics workshop</title>" % escape(args.title), html, count=1)
    html = DESC_RE.sub(lambda _m: '<meta name="description" content="%s">' % escape(description, quote=True), html, count=1)
    html = H1_RE.sub(lambda _m: '<h1 id="page-title">%s</h1>' % escape(args.title), html, count=1)
    if args.subtitle:
        html = LEAD_RE.sub(lambda _m: '<p class="lead" id="page-subtitle">%s</p>' % escape(args.subtitle), html, count=1)
    html = CAP_RE.sub(lambda _m: '<p class="table-caption" id="table-caption">%s</p>' % escape(caption), html, count=1)

    # Optional explanation / glossary, written statically into the page.
    intro = args.intro
    if args.intro_file:
        with open(args.intro_file, encoding="utf-8") as fh:
            intro = fh.read()
    if intro.strip():
        html, n_intro = INTRO_RE.subn(
            lambda _m: '<section class="intro" id="intro">\n%s\n      </section>' % intro.strip(),
            html, count=1,
        )
        if n_intro != 1:
            sys.exit("Could not locate the intro section in the template.")

    out = args.out or (os.path.splitext(args.data)[0] + ".html")
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(html)

    print("Wrote %s" % out)
    print("  rows embedded : %s%s" % (f"{kept:,}", " (truncated)" if truncated else ""))
    print("  columns       : %s" % (len(header_line.split("\t")) if args.delimiter == "\t" else "auto"))
    print("  size          : %.1f KB" % (os.path.getsize(out) / 1024.0))


if __name__ == "__main__":
    main()
