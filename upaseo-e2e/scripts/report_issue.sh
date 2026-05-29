#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash upaseo-e2e/scripts/report_issue.sh --title "..." --body-file /tmp/body.md [--label bug] [--repo owner/name]

Behavior:
  1. Try `gh issue create`
  2. If that fails or `gh` is unavailable, write a local fallback file to `.github/issues/`
EOF
}

TITLE=""
BODY_FILE=""
LABEL=""
REPO=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --title)
      TITLE="${2:-}"
      shift 2
      ;;
    --body-file)
      BODY_FILE="${2:-}"
      shift 2
      ;;
    --label)
      LABEL="${2:-}"
      shift 2
      ;;
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$TITLE" ] || [ -z "$BODY_FILE" ]; then
  echo "--title and --body-file are required" >&2
  usage >&2
  exit 1
fi

if [ ! -f "$BODY_FILE" ]; then
  echo "Body file not found: $BODY_FILE" >&2
  exit 1
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ISSUE_DIR="${ROOT}/.github/issues"
TIMESTAMP="$(date -u +%Y%m%d-%H%M%S)"
SLUG="$(printf '%s' "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/-\\{2,\\}/-/g; s/^-//; s/-$//' | cut -c1-80)"

if [ -z "$SLUG" ]; then
  SLUG="issue"
fi

GH_ERROR=""

if command -v gh >/dev/null 2>&1; then
  GH_ARGS=(issue create --title "$TITLE" --body-file "$BODY_FILE")
  if [ -n "$LABEL" ]; then
    GH_ARGS+=(--label "$LABEL")
  fi
  if [ -n "$REPO" ]; then
    GH_ARGS+=(--repo "$REPO")
  fi

  if GH_OUTPUT="$(gh "${GH_ARGS[@]}" 2>&1)"; then
    printf '%s\n' "$GH_OUTPUT"
    exit 0
  fi

  GH_ERROR="$GH_OUTPUT"
else
  GH_ERROR="gh command not found"
fi

mkdir -p "$ISSUE_DIR"
LOCAL_PATH="${ISSUE_DIR}/${TIMESTAMP}-${SLUG}.md"

{
  printf '# %s\n\n' "$TITLE"
  printf 'Status: local-fallback\n'
  printf 'Created: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [ -n "$LABEL" ]; then
    printf 'Label: %s\n' "$LABEL"
  fi
  if [ -n "$REPO" ]; then
    printf 'Repo: %s\n' "$REPO"
  fi
  printf '\n## GH Fallback Reason\n\n'
  printf '```text\n%s\n```\n\n' "$GH_ERROR"
  cat "$BODY_FILE"
} > "$LOCAL_PATH"

printf '%s\n' "$LOCAL_PATH"
