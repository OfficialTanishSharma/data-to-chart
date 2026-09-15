# data-to-chart

Turn raw data (CSV, JSON, pasted table) into an interactive, self-contained
HTML chart. Powered by Plotly.

## When to use

Use when the user provides data and asks for a chart, graph, plot, or
visualization. Do not use for dashboards, image exports, or when no data
is provided.

## How to use

1. Read `SKILL.md` — it has the full workflow, chart selection rules, and
   the JSON schema.
2. Emit a JSON spec following that schema.
3. Run exactly:
   `data-to-chart --input <spec.json> --output <chart.html>`
4. Report the output path to the user.

## Requirements

- Python 3.10+
- The `data-to-chart` wrapper on your PATH

First time? Run `./install.sh` (Unix) or `.\install.ps1` (Windows) to put
`data-to-chart` on your PATH and install the skill.

## Safety

Only run the command pattern above. No arbitrary bash, no code generation
for chart rendering — the renderer script is the sole rendering path.