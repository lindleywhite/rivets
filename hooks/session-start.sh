#!/usr/bin/env bash
# SessionStart hook for rivets plugin

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Detect environment capabilities
capabilities=""

# Check for beads — use bd doctor which works regardless of storage location
# (handles .beads/ directory, BEADS_DB env var, custom db: config, etc.)
if command -v bd &>/dev/null && bd doctor 2>&1 | grep -q '✓  Installation'; then
    capabilities="${capabilities}beads "
fi

# Check for ai/ directory structure
if [ -d "ai/current" ]; then
    capabilities="${capabilities}ai-directory "
fi

# Read using-rivets content
using_rivets_content=$(cat "${PLUGIN_ROOT}/skills/using-rivets/SKILL.md" 2>&1 || echo "Error reading using-rivets skill")

# Escape string for JSON embedding
escape_for_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

using_rivets_escaped=$(escape_for_json "$using_rivets_content")
capabilities_escaped=$(escape_for_json "$capabilities")

# Output context injection as JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<rivets-plugin>\nYou have Rivets — a structured engineering workflow.\n\nDetected capabilities: ${capabilities_escaped}\n\n**Below is your 'rivets:using-rivets' skill — your introduction to the workflow system. For all other skills, use the 'Skill' tool:**\n\n${using_rivets_escaped}\n</rivets-plugin>"
  }
}
EOF

exit 0
