#!/usr/bin/env python3
"""
render_chart.py — Render a structured JSON chart spec into a self-contained HTML file.

The JSON schema is defined in SKILL.md. This script is the ONLY rendering path
the skill is allowed to invoke — it never executes user-provided code.

Usage:
    python render_chart.py --input spec.json --output chart.html

Exit codes:
    0  success
    1  unexpected render error
    2  invalid spec (validation failure)
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import plotly.graph_objects as go


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

VALID_CHART_TYPES = {"bar", "line", "pie", "scatter", "area", "heatmap"}

DEFAULT_COLORS = [
    "#4C6EF5", "#F76707", "#12B886", "#E64980", "#7950F2",
    "#FAB005", "#15AABF", "#FA5252", "#82C91E", "#BE4BDB",
]

BASE_TEMPLATE = "plotly_white"
FONT_STACK = (
    "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, "
    "'Helvetica Neue', Arial, sans-serif"
)


# ---------------------------------------------------------------------------
# Errors
# ---------------------------------------------------------------------------

class SpecError(ValueError):
    """Raised when the JSON spec is invalid or incomplete."""


# ---------------------------------------------------------------------------
# Loading + validation
# ---------------------------------------------------------------------------

def load_spec(path: Path) -> dict:
    if not path.exists():
        raise SpecError(f"Input file not found: {path}")
    try:
        with path.open("r", encoding="utf-8") as f:
            spec = json.load(f)
    except json.JSONDecodeError as e:
        raise SpecError(f"Invalid JSON in {path}: {e}") from e

    if not isinstance(spec, dict):
        raise SpecError("Top-level JSON must be an object.")
    return spec


def validate_spec(spec: dict) -> None:
    chart_type = spec.get("chart_type")
    if not chart_type:
        raise SpecError("Missing required field: 'chart_type'.")
    if chart_type not in VALID_CHART_TYPES:
        raise SpecError(
            f"Invalid chart_type '{chart_type}'. "
            f"Must be one of: {sorted(VALID_CHART_TYPES)}."
        )

    data = spec.get("data")
    if not isinstance(data, dict):
        raise SpecError("Missing or invalid 'data' object.")

    labels = data.get("labels", [])

    if chart_type != "scatter":
        if not isinstance(labels, list) or not labels:
            raise SpecError("'data.labels' must be a non-empty array.")
    else:
        if not isinstance(labels, list):
            raise SpecError("'data.labels' must be an array if provided.")

    series = data.get("series")
    if not isinstance(series, list) or not series:
        raise SpecError("'data.series' must be a non-empty array.")

    for i, s in enumerate(series):
        if not isinstance(s, dict):
            raise SpecError(f"data.series[{i}] must be an object.")
        if not s.get("name"):
            raise SpecError(f"data.series[{i}] is missing 'name'.")
        values = s.get("values")
        if not isinstance(values, list) or not values:
            raise SpecError(
                f"data.series[{i}].values must be a non-empty array."
            )

    if chart_type == "pie" and len(series) > 1:
        raise SpecError(
            f"Pie chart supports exactly one series (got {len(series)})."
        )

    if chart_type == "heatmap":
        for s in series:
            if len(s["values"]) != len(labels):
                raise SpecError(
                    f"Heatmap row '{s['name']}' has {len(s['values'])} values, "
                    f"expected {len(labels)} (matching labels)."
                )
        return

    if chart_type == "scatter":
        for s in series:
            x_values = s.get("x_values")
            if not isinstance(x_values, list) or not x_values:
                raise SpecError(
                    f"Scatter chart requires 'x_values' in each series "
                    f"(missing in series '{s['name']}')."
                )
            if len(x_values) != len(s["values"]):
                raise SpecError(
                    f"Series '{s['name']}': x_values length ({len(x_values)}) "
                    f"must match values length ({len(s['values'])})."
                )
        return

    for s in series:
        if len(s["values"]) != len(labels):
            raise SpecError(
                f"Series '{s['name']}' has {len(s['values'])} values, "
                f"expected {len(labels)} (matching labels)."
            )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _pick_color(index: int, options: dict) -> str:
    custom = options.get("colors")
    if isinstance(custom, list) and index < len(custom):
        return str(custom[index])
    return DEFAULT_COLORS[index % len(DEFAULT_COLORS)]


def _hover_extra(name: str) -> str:
    return "%{x}: %{y}<extra>" + str(name) + "</extra>"


# ---------------------------------------------------------------------------
# Chart builders
# ---------------------------------------------------------------------------

def build_bar(spec, labels, series, options):
    stacked = bool(options.get("stacked", False))
    horizontal = bool(options.get("horizontal", False))
    fig = go.Figure()

    for i, s in enumerate(series):
        color = _pick_color(i, options)
        if horizontal:
            fig.add_trace(go.Bar(
                x=s["values"], y=labels, name=s["name"],
                orientation="h", marker_color=color,
                hovertemplate="%{y}: %{x}<extra>" + str(s["name"]) + "</extra>",
            ))
        else:
            fig.add_trace(go.Bar(
                x=labels, y=s["values"], name=s["name"],
                marker_color=color,
                hovertemplate=_hover_extra(s["name"]),
            ))

    fig.update_layout(barmode="stack" if stacked else "group")
    return fig


def build_line(spec, labels, series, options):
    fig = go.Figure()
    for i, s in enumerate(series):
        color = _pick_color(i, options)
        fig.add_trace(go.Scatter(
            x=labels, y=s["values"], mode="lines+markers", name=s["name"],
            line=dict(color=color, width=2.5),
            marker=dict(size=7, color=color),
            hovertemplate=_hover_extra(s["name"]),
        ))
    return fig


def build_area(spec, labels, series, options):
    stacked = bool(options.get("stacked", True))
    fig = go.Figure()
    for i, s in enumerate(series):
        color = _pick_color(i, options)
        trace_kwargs = dict(
            x=labels, y=s["values"], mode="lines", name=s["name"],
            line=dict(color=color, width=2),
            hovertemplate=_hover_extra(s["name"]),
        )
        if stacked:
            trace_kwargs["stackgroup"] = "one"
        else:
            trace_kwargs["fill"] = "tozeroy"
        fig.add_trace(go.Scatter(**trace_kwargs))
    return fig


def build_pie(spec, labels, series, options):
    s = series[0]
    custom = options.get("colors")
    colors = custom if isinstance(custom, list) and custom else DEFAULT_COLORS
    fig = go.Figure(go.Pie(
        labels=labels, values=s["values"],
        marker=dict(colors=[colors[i % len(colors)] for i in range(len(labels))]),
        textinfo="label+percent", textposition="auto",
        hovertemplate="%{label}: %{value} (%{percent})<extra></extra>",
    ))
    return fig


def build_scatter(spec, labels, series, options):
    fig = go.Figure()
    for i, s in enumerate(series):
        color = _pick_color(i, options)
        fig.add_trace(go.Scatter(
            x=s["x_values"], y=s["values"], mode="markers", name=s["name"],
            marker=dict(size=10, color=color, line=dict(width=0)),
            hovertemplate="(%{x}, %{y})<extra>" + str(s["name"]) + "</extra>",
        ))
    return fig


def build_heatmap(spec, labels, series, options):
    z = [s["values"] for s in series]
    y = [s["name"] for s in series]
    colorscale = options.get("colorscale", "Blues")
    fig = go.Figure(go.Heatmap(
        z=z, x=labels, y=y, colorscale=colorscale,
        hovertemplate="%{y} / %{x}: %{z}<extra></extra>",
    ))
    return fig


BUILDERS = {
    "bar": build_bar, "line": build_line, "area": build_area,
    "pie": build_pie, "scatter": build_scatter, "heatmap": build_heatmap,
}


# ---------------------------------------------------------------------------
# Layout
# ---------------------------------------------------------------------------

def _apply_common_layout(fig, spec, chart_type, num_series):
    title = spec.get("title") or ""
    show_legend = chart_type == "pie" or num_series > 1
    if chart_type == "pie":
        legend = dict(orientation="v", yanchor="middle", y=0.5,
                      xanchor="left", x=1.02)
    else:
        legend = dict(orientation="h", yanchor="bottom", y=1.02,
                      xanchor="right", x=1)
    hovermode = "x unified" if chart_type in ("line", "area") else "closest"

    layout_kwargs = dict(
        template=BASE_TEMPLATE,
        font=dict(family=FONT_STACK, size=13, color="#1f2933"),
        margin=dict(l=64, r=40, t=72 if title else 40, b=56),
        autosize=True, hovermode=hovermode,
        showlegend=show_legend, legend=legend,
        paper_bgcolor="white", plot_bgcolor="white",
    )
    if title:
        layout_kwargs["title"] = dict(
            text=title, x=0.5, xanchor="center", font=dict(size=20)
        )
    fig.update_layout(**layout_kwargs)


def _apply_axis_labels(fig, spec, chart_type):
    if chart_type in ("pie", "heatmap"):
        return
    x_label = spec.get("x_label", "") or ""
    y_label = spec.get("y_label", "") or ""
    options = spec.get("options") or {}
    if chart_type == "bar" and options.get("horizontal"):
        x_label, y_label = y_label, x_label
    fig.update_xaxes(title_text=x_label, showgrid=True, gridcolor="#e4e7eb")
    fig.update_yaxes(title_text=y_label, showgrid=True, gridcolor="#e4e7eb")


# ---------------------------------------------------------------------------
# Orchestration
# ---------------------------------------------------------------------------

def render(spec: dict):
    chart_type = spec["chart_type"]
    data = spec["data"]
    labels = data.get("labels", [])
    series = data["series"]
    options = spec.get("options") or {}
    fig = BUILDERS[chart_type](spec, labels, series, options)
    _apply_common_layout(fig, spec, chart_type, len(series))
    _apply_axis_labels(fig, spec, chart_type)
    return fig


def write_html(fig, out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.write_html(
        str(out_path),
        include_plotlyjs="inline",
        full_html=True,
        config={
            "responsive": True,
            "displaylogo": False,
            "modeBarButtonsToRemove": ["lasso2d", "select2d"],
        },
    )


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        description="Render a JSON chart spec into a self-contained HTML file."
    )
    parser.add_argument("--input", "-i", required=True, type=Path,
                        help="Path to the JSON chart spec.")
    parser.add_argument("--output", "-o", required=True, type=Path,
                        help="Path to write the HTML file.")
    args = parser.parse_args(argv)

    try:
        spec = load_spec(args.input)
        validate_spec(spec)
        fig = render(spec)
        write_html(fig, args.output)
    except SpecError as e:
        print(f"Spec error: {e}", file=sys.stderr)
        return 2
    except Exception as e:
        print(f"Render error: {e}", file=sys.stderr)
        return 1

    print(f"Wrote {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())