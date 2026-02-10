#!/usr/bin/env bash
#
# scaffold_plan.sh
#
# Creates a new plan file in ai/current/ with the correct YYYY-MM-DD prefix,
# YAML frontmatter, and section template. Prevents dateless/templateless plans.
#
# Usage:
#   bash scaffold_plan.sh "auth waterfall optimization"
#   bash scaffold_plan.sh "feature flags" --owner lindley --tags "backend,infrastructure"
#
# Output: path to the created file

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: scaffold_plan.sh <plan-name> [--owner NAME] [--tags TAG1,TAG2]" >&2
  exit 1
fi

NAME="$1"
shift

# Defaults
OWNER="engineering"
TAGS="implementation"

# Parse optional flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) OWNER="$2"; shift 2 ;;
    --tags)  TAGS="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Convert name to kebab-case filename
SLUG=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
DATE=$(date +%Y-%m-%d)
ISO_DATE=$(date +%Y-%m-%dT00:00:00Z)
FILENAME="${DATE}-${SLUG}.md"

# Ensure ai/current/ exists
mkdir -p ai/current

FILEPATH="ai/current/${FILENAME}"

# Check for duplicates
if [[ -f "$FILEPATH" ]]; then
  echo "Error: $FILEPATH already exists" >&2
  exit 1
fi

# Format tags as YAML array
IFS=',' read -ra TAG_ARRAY <<< "$TAGS"
TAG_YAML=""
for tag in "${TAG_ARRAY[@]}"; do
  tag=$(echo "$tag" | tr -d ' ')
  TAG_YAML="${TAG_YAML}${TAG_YAML:+, }${tag}"
done

# Convert slug to title case for heading
TITLE=$(echo "$NAME" | sed 's/\b\(.\)/\u\1/g' 2>/dev/null || echo "$NAME")

cat > "$FILEPATH" << EOF
---
date: ${ISO_DATE}
status: planning
owner: ${OWNER}
dependencies: []
tags: [${TAG_YAML}]
---

# ${TITLE} Implementation Plan

## Overview

[Brief description of what we're implementing and why]

## Current State Analysis

[What exists now, what's missing, key constraints discovered]

### Key Discoveries:
- [Important finding with file:line reference]

## Desired End State

[Specification of the desired end state and how to verify it]

## What We're NOT Doing

[Explicitly list out-of-scope items to prevent scope creep]

## Implementation Approach

[High-level strategy and reasoning]

## Phase 1: [Descriptive Name]

### Overview
[What this phase accomplishes]

### Changes Required:

#### 1. [Component/File Group]
**File**: \`path/to/file.ext\`
**Changes**: [Summary of changes]

### Success Criteria:

#### Automated Verification:
- [ ] Tests pass
- [ ] Type checking passes
- [ ] Linting passes

#### Manual Verification:
- [ ] Feature works as expected
- [ ] No regressions in related features

---

## Phase 2: [Descriptive Name]

[Similar structure...]

---

## Testing Strategy

### Unit Tests:
- [What to test]

### Integration Tests:
- [End-to-end scenarios]

## References

- Related research: \`ai/research/...\`
- Similar implementation: \`[file:line]\`
EOF

echo "$FILEPATH"
