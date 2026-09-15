---
name: data-to-chart
description: Converts raw data (CSV, JSON, or pasted tables) into a beautiful, interactive, self-contained HTML chart. Use when the user provides data and asks for a chart, graph, plot, or visualization. The skill decides the best chart type, emits a structured JSON spec, and renders it via a Python script.
allowed-tools:
  - Bash
  - Read
  - Write
---

# Data to Chart

Turn raw data into an interactive HTML chart using a strict two-stage pipeline:

1. **You (the agent)** — parse, validate, choose chart type, emit a JSON spec.
2. **`data-to-chart`** (wrapper around `render_chart.py`) — reads the spec,
   renders a self-contained HTML file.

You never write chart-rendering code yourself. You only produce the JSON spec
and invoke the wrapper. This keeps output deterministic and consistent.

---

## Requirements & setup

- Python 3.10+
- The `data-to-chart` wrapper on your PATH

**First time?** Run the installer once:

- Unix / macOS: `./install.sh`
- Windows PowerShell: `.\install.ps1`

This copies the skill into `~/.claude/skills/data-to-chart/` and places the
`data-to-chart` wrapper on your PATH. It also checks Python and Plotly and
prints install hints if either is missing.

If `data-to-chart` is not on PATH and you cannot install it, fall back to:
