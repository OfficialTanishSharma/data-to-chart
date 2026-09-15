# data-to-chart

[![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-blue)](https://www.python.org/)
[![License MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Agents](https://img.shields.io/badge/agents-10%2B-orange)](#installation)

Turn raw data (CSV, JSON, or pasted tables) into beautiful, interactive,
self-contained HTML charts — powered by Plotly.

Built as an **AI Agent Skill**: works with Claude Code, Cursor, Windsurf
(Devin Desktop), Cline, Continue, Codex, Gemini CLI, GitHub Copilot,
OpenCode, Amp, and anything else that reads `AGENTS.md`.

## Why this approach

LLMs are great at reasoning about data, terrible at hand-writing chart code.
This skill splits responsibilities:

- **Agent** — parses the data, picks the best chart type, emits a strict JSON spec.
- **`render_chart.py`** — validates the spec, renders the HTML.

No Mermaid-style syntax errors, no inconsistent styling, no "it worked last
time but not now." The agent never writes chart code — it only produces data.

## Requirements

- **Python 3.10 or newer**
- **Plotly** — installed via `pip install -r requirements.txt`
- **`~/.local/bin`** (or `$XDG_BIN_HOME`) on your `PATH`

## Installation

### Quick install (recommended)

> **Note:** The quick install sets up the wrapper and the Claude Code
> global skill only. For Cursor, Windsurf, Cline, Continue, or `AGENTS.md`
> agents, use the **per-agent manual install** (below) or a **sync tool**.

**Unix / macOS:**

```bash
git clone https://github.com/OfficialTanishSharma/data-to-chart.git
cd data-to-chart
./install.sh