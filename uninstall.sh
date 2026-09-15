#!/usr/bin/env bash
# uninstall.sh — Remove the data-to-chart skill.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="data-to-chart"
GLOBAL_SKILL_DIR="${HOME}/.claude/skills/${SKILL_NAME}"
BIN_DIR="${XDG_BIN_HOME:-${HOME}/.local/bin}"
WRAPPER_PATH="${BIN_DIR}/${SKILL_NAME}"
PROJECT_SKILL_DIR="${SCRIPT_DIR}/.claude/skills/${SKILL_NAME}"

MODE="global"
ASSUME_YES=0

for arg in "$@"; do
  case "$arg" in
    --project) MODE="project" ;;
    --yes|-y)  ASSUME_YES=1 ;;
    -h|--help)
      cat <<EOF
Usage: $0 [--project] [--yes]
  (default)   Remove global install (skill dir + wrapper).
  --project   Remove project-local skill dir only.
  --yes, -y   Skip confirmation prompt.
EOF
      exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

info() { printf '  %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*" >&2; }

removed_any=0

remove_dir() {
  local d="$1"
  if [[ -d "$d" ]]; then rm -rf "$d"; info "Removed: $d"; removed_any=1
  else info "Not found (skipping): $d"; fi
}

remove_file() {
  local f="$1"
  if [[ -f "$f" ]]; then rm -f "$f"; info "Removed: $f"; removed_any=1
  else info "Not found (skipping): $f"; fi
}

confirm() {
  local prompt="$1"
  [[ "${ASSUME_YES}" -eq 1 ]] && return 0
  [[ -t 0 ]] || return 1
  read -rp "${prompt} [y/N] " ans
  [[ "${ans}" =~ ^[Yy]$ ]]
}

if [[ "${MODE}" == "project" ]]; then
  confirm "Remove project-local ${SKILL_NAME}?" || { echo "Aborted."; exit 0; }
  echo "Uninstalling ${SKILL_NAME} (project-local)..."
  remove_dir "${PROJECT_SKILL_DIR}"
else
  confirm "Remove global ${SKILL_NAME} install?" || { echo "Aborted."; exit 0; }
  echo "Uninstalling ${SKILL_NAME} (global)..."
  remove_dir "${GLOBAL_SKILL_DIR}"
  remove_file "${WRAPPER_PATH}"
fi

echo
if [[ "${removed_any}" -eq 1 ]]; then
  echo "Done."
  echo
  echo "Note: we never modified your PATH or shell rc files, so there is"
  echo "nothing to revert there. If you manually added '${BIN_DIR}' to"
  echo "PATH, remove that line yourself."
else
  echo "Nothing to remove."
fi