---
description: Turn raw data (CSV, JSON, or pasted table) into an interactive HTML chart
---

# data-to-chart

Turn raw data into a beautiful, interactive, self-contained HTML chart
using Plotly. Full instructions live in `SKILL.md` at the repo root.

## Do not use for

Dashboards, image exports (PNG/SVG), or when no data is provided.

## Workflow

### 1. Acquire the data

- If the user pasted data, use it directly.
- If the user gave a file path, read it.
- If the data is remote, ask the user to paste it or download it first.

### 2. Parse and validate

- Detect format: CSV, TSV, JSON, or markdown table.
- Confirm at least one categorical/ordered column and one numeric column.
- If parsing fails or columns are ambiguous, **stop and ask the user**.

### 3. Choose the chart type

| Data shape | Chart |
|---|---|
| 1 categorical + 1 numeric, 12 categories or fewer | `bar` |
| 1 categorical + 1 numeric, more than 12 categories | `bar` (horizontal) |
| Parts-of-whole, 8 categories or fewer | `pie` |
| Ordered/time + numeric | `line` |
| Ordered/time + numeric, cumulative | `area` |
| 2 numerics, correlation | `scatter` |
| 2 categoricals + 1 numeric | `heatmap` |

Tie-breakers: unsure `pie` vs `bar` — use `bar`. Unsure `line` vs `area` — use `line`.

### 4. Emit the JSON spec

Write to `/tmp/chart_spec.json`.

<!-- Canonical schema: SKILL.md — "JSON schema" section. Keep in sync. -->

```json
{
  "chart_type": "bar | line | pie | scatter | area | heatmap",
  "title": "string",
  "x_label": "string",
  "y_label": "string",
  "data": {
    "labels": ["..."],
    "series": [
      { "name": "string", "values": [0, 1, 2],
        "x_values": [0, 1, 2] }
    ]
  },
  "options": { "stacked": false, "horizontal": false }
}