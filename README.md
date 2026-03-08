# Sitemap & Feed Extractor

[![Python 3.13+](https://img.shields.io/badge/python-3.13%2B-blue?logo=python&logoColor=white)](https://www.python.org/downloads/)
[![Linting: Ruff](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json)](https://github.com/astral-sh/ruff)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![uv](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/uv/main/assets/badge/v0.json)](https://github.com/astral-sh/uv)

Smart date-filtered URL extraction from sitemaps, RSS feeds, and Atom feeds. Designed for LLM/agent workflows where full sitemaps are too large for context windows.

## How It Works

Sitemaps can contain thousands of entries. Instead of dumping the entire XML into a prompt, this script intelligently narrows results:

**Top N mode** (`--top`): Starts from the current month and expands backward one month at a time until N results are collected. A `--top 10` on a sitemap with 10,000 entries returns only the 10 most recent — fast and context-friendly.

**Date range mode** (`--from` / `--to`): Returns all entries within a specific date range.

**Route filtering** (`--route`): Pre-filters entries by URL path substring before applying date/top-N logic. Excludes the bare section index (e.g. `/blog` itself). Essential for sitemaps without `<lastmod>` dates where you only want a specific section (e.g. `--route blog` to get only blog posts, not static pages like `/about` or `/settings`). When used alone (without `--top` or `--from`), returns **all** matching entries — no need to guess the count.

## Features

| Feature | Description |
|---------|-------------|
| **Route filtering** | `--route` pre-filters URLs by path before date logic; standalone returns all matches |
| **RSS 2.0 feeds** | Auto-detected; parses `<item>` with `<pubDate>`, title, author |
| **Atom feeds** | Auto-detected; parses `<entry>` with `<updated>`, title, author |
| **Smart date expansion** | Month-by-month backward scan — only fetches what's needed |
| **Sitemap index support** | Recursive handling up to 10 levels deep |
| **Google News sitemaps** | Extracts `<news:publication_date>`, title, publication name |
| **Gzip `.xml.gz`** | Transparent decompression of compressed sitemaps |
| **Auto-discovery** | `--discover` finds sitemaps via robots.txt + common paths |
| **Error tolerance** | Recovers from truncated/malformed XML gracefully |
| **Multiple outputs** | Rich table, JSON, URLs-only, file save |
| **Fetch statistics** | Tracks bytes downloaded, time, error count |

## Usage

```bash
# Top 10 most recent posts
uv run sitemap/sitemap_feed_extractor.py https://example.com/sitemap.xml --top 10

# Filter by route — only blog posts from the sitemap
uv run sitemap/sitemap_feed_extractor.py https://windsurf.com/sitemap.xml --top 10 --route blog

# Get ALL URLs matching a route (no --top needed — returns every match)
uv run sitemap/sitemap_feed_extractor.py https://platform.claude.com/sitemap.xml --route agent-sdk

# Combine route + date range
uv run sitemap/sitemap_feed_extractor.py https://example.com/sitemap.xml --from 2026-01-01 --to 2026-03-07 --route docs

# Auto-discover sitemaps from a homepage
uv run sitemap/sitemap_feed_extractor.py https://example.com --top 10 --discover

# Date range
uv run sitemap/sitemap_feed_extractor.py https://example.com/sitemap.xml --from 2026-01-01 --to 2026-03-07

# Top 20 from a specific reference date
uv run sitemap/sitemap_feed_extractor.py https://example.com/sitemap.xml --top 20 --start-date 2026-02-15

# JSON output (for piping to other tools)
uv run sitemap/sitemap_feed_extractor.py https://example.com/sitemap.xml --top 10 --json

# URLs only, one per line (great for piping to trafilatura_scraper.py)
uv run sitemap/sitemap_feed_extractor.py https://example.com/sitemap.xml --top 10 --urls-only

# Save URLs to a file
uv run sitemap/sitemap_feed_extractor.py https://example.com/sitemap.xml --top 10 --output urls.txt

# RSS and Atom feeds work too — auto-detected
uv run sitemap/sitemap_feed_extractor.py https://aws.amazon.com/blogs/aws/feed/ --top 10
uv run sitemap/sitemap_feed_extractor.py https://github.com/astral-sh/uv/releases.atom --top 5
```

## CLI Options

| Option | Description |
|--------|-------------|
| `--top N`, `-n N` | Get the N most recent URLs |
| `--route PATH`, `-r PATH` | Filter URLs by path substring; can be used alone to get all matches, or combined with `--top`/`--from` |
| `--from YYYY-MM-DD` | Start of date range (inclusive) |
| `--to YYYY-MM-DD` | End of date range (inclusive, defaults to today) |
| `--discover` | Treat URL as homepage — find sitemaps via robots.txt + common paths |
| `--start-date YYYY-MM-DD` | Reference date for `--top` mode (defaults to today) |
| `--json` | Output as JSON |
| `--urls-only` | Output URLs only, one per line |
| `--output FILE`, `-o FILE` | Save URLs to a file |

## Why Not `ultimate-sitemap-parser`?

We evaluated [GateNLP/ultimate-sitemap-parser](https://github.com/GateNLP/ultimate-sitemap-parser) (USP). It's a comprehensive parser library (XML, RSS, Atom, plain text sitemaps) battle-tested with ~1M URLs, but:

- **No date filtering** — returns *all* pages, you still need to iterate everything yourself
- **No CLI** — library only, requires writing wrapper code
- **GPLv3+ license** — viral/restrictive
- **Old Python** — targets 3.5+, no modern type hints
- **Not LLM-aware** — no concept of "give me the top N recent URLs efficiently"

We borrowed USP's best ideas (gzip support, error tolerance, news sitemaps, sitemap discovery) and built them into a purpose-built CLI with the smart date-expansion strategy that makes this tool useful for LLM agent workflows.

## Dependencies

Uses PEP 723 inline metadata — no `requirements.txt` needed. `uv run` handles everything:

- `requests` — HTTP fetching
- `rich` — Terminal UI (tables, panels)
- `defusedxml` — Safe XML parsing
