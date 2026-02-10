#!/usr/bin/env bash
#
# parse_plan_frontmatter.sh
#
# One-shot data gatherer for plan auditing. Extracts frontmatter fields,
# checkbox counts, last git activity, and days since last touch.
#
# Output: TSV with columns:
#   filename, status, date, owner, checked, unchecked, total, pct, last_git, days_ago
#
# Usage:
#   bash parse_plan_frontmatter.sh
#   bash parse_plan_frontmatter.sh ai/current/specific-plan.md

set -euo pipefail

PLAN_DIR="${1:-ai/current}"
TODAY=$(date +%s)

# If a specific file was passed, just process that file
if [[ -f "$PLAN_DIR" ]]; then
  FILES=("$PLAN_DIR")
else
  FILES=()
  for f in "$PLAN_DIR"/*.md; do
    [[ -f "$f" ]] && FILES+=("$f")
  done
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No plan files found in $PLAN_DIR" >&2
  exit 1
fi

# Header
printf "filename\tstatus\tdate\towner\tchecked\tunchecked\ttotal\tpct\tlast_git\tdays_ago\n"

for file in "${FILES[@]}"; do
  filename=$(basename "$file" .md)
  status=""
  date_val=""
  owner=""

  # Detect if file has YAML frontmatter (starts with ---)
  first_line=$(head -1 "$file")
  if [[ "$first_line" == "---" ]]; then
    # Extract YAML frontmatter between --- delimiters
    frontmatter=$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$file")
    status=$(echo "$frontmatter" | grep -E '^status:' | head -1 | sed 's/^status:[[:space:]]*//' | tr -d '"' | tr -d "'" || true)
    date_val=$(echo "$frontmatter" | grep -E '^date:' | head -1 | sed 's/^date:[[:space:]]*//' | sed 's/T.*//' | tr -d '"' | tr -d "'" || true)
    owner=$(echo "$frontmatter" | grep -E '^owner:' | head -1 | sed 's/^owner:[[:space:]]*//' | tr -d '"' | tr -d "'" || true)
  else
    # Try inline format: **Status:** value or **Date:** value (macOS-compatible)
    status=$(grep -m1 '\*\*Status:\*\*' "$file" 2>/dev/null | sed 's/.*\*\*Status:\*\*[[:space:]]*//' || true)
    date_val=$(grep -m1 '\*\*Date:\*\*' "$file" 2>/dev/null | sed 's/.*\*\*Date:\*\*[[:space:]]*//' || true)
    owner=$(grep -m1 '\*\*Owner:\*\*' "$file" 2>/dev/null | sed 's/.*\*\*Owner:\*\*[[:space:]]*//' || true)
  fi

  # Normalize empty values
  [[ -z "$status" ]] && status="unknown"
  [[ -z "$date_val" ]] && date_val="unknown"
  [[ -z "$owner" ]] && owner="unknown"

  # Count checkboxes (use -E for extended regex on macOS)
  checked=$(grep -cE '\- \[[xX]\]' "$file" 2>/dev/null || true)
  checked=${checked:-0}
  unchecked=$(grep -c '\- \[ \]' "$file" 2>/dev/null || true)
  unchecked=${unchecked:-0}
  total=$((checked + unchecked))

  if [[ $total -gt 0 ]]; then
    pct=$((checked * 100 / total))
  else
    pct="-"
  fi

  # Last git activity on this file
  last_git=$(git log -1 --format="%ci" -- "$file" 2>/dev/null | sed 's/ .*//' || true)
  last_git=${last_git:-unknown}

  # Days since last git activity (macOS and Linux compatible)
  if [[ "$last_git" != "unknown" ]]; then
    last_epoch=$(date -j -f "%Y-%m-%d" "$last_git" +%s 2>/dev/null || date -d "$last_git" +%s 2>/dev/null || echo "")
    if [[ -n "$last_epoch" ]]; then
      days_ago=$(( (TODAY - last_epoch) / 86400 ))
    else
      days_ago="-"
    fi
  else
    days_ago="-"
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$filename" "$status" "$date_val" "$owner" "$checked" "$unchecked" "$total" "$pct" "$last_git" "$days_ago"
done
