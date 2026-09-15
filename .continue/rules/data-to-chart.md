---
description: Turn raw data (CSV, TSV, or pasted table) into interactive HTML charts
globs:
  - "**/*.csv"
  - "**/*.tsv"
alwaysApply: false
---

# data-to-chart

When the user provides raw data and asks for a chart, graph, plot, or
visualization, follow the workflow in `SKILL.md` at the repo root.

## Quick reference

- **Full instructions:** `SKILL.md`
- **Renderer:** `render_chart.py`
- **Examples:** `examples/*.json`
- **Deps:** `pip install -r requirements.txt`

## Workflow (summary)

1. Parse the data (CSV, TSV, JSON, or pasted table).
2. Pick a chart type — see the selection table in `SKILL.md`.
3. Emit a JSON spec matching the schema in `SKILL.md`.
4. Run exactly:
   `data-to-chart --input <spec.json> --output <chart.html>`
5. Report the output path.

## Rules

- Never write chart-rendering code yourself. Only emit JSON specs.
- Only run the command pattern above. No arbitrary bash.
- If the data is empty, malformed, or ambiguous, stop and ask the user.
- Pie charts: max 8 slices, then downgrade to `bar`.

## Supported chart types

`bar`, `line`, `area`, `pie`, `scatter`, `heatmap`