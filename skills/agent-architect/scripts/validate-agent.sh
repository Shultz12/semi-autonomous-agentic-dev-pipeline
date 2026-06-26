#!/bin/bash
# Validates agent/skill files after Write operations
# Exit codes:
#   0 - Success or file not applicable
#   2 - Validation errors (blocks tool, shows feedback)

# Read hook input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only validate .md files in .claude/ agent/skill/command directories
if [[ ! "$FILE_PATH" =~ \.claude/.*(agents|skills|commands).*\.md$ ]]; then
  exit 0
fi

# Check if file exists
if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

CONTENT=$(cat "$FILE_PATH" 2>/dev/null)
ERRORS=""

# Check YAML frontmatter exists
if [[ ! "$CONTENT" =~ ^---[[:space:]] ]]; then
  ERRORS+="- Missing YAML frontmatter (file must start with ---)\n"
fi

# Check required 'name' field
if [[ ! "$CONTENT" =~ name:[[:space:]] ]]; then
  ERRORS+="- Missing 'name' field in frontmatter\n"
fi

# Check required 'description' field
if [[ ! "$CONTENT" =~ description:[[:space:]] ]]; then
  ERRORS+="- Missing 'description' field in frontmatter\n"
fi

# Extract name and check kebab-case convention
NAME=$(echo "$CONTENT" | grep -oP '(?<=^name: )[^\s]+' | head -1)
if [[ -n "$NAME" && ! "$NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  ERRORS+="- Name '$NAME' must be kebab-case (lowercase letters, numbers, hyphens only)\n"
fi

# Check for Windows-style backslash paths
if [[ "$CONTENT" =~ \\ ]]; then
  ERRORS+="- Found Windows-style backslash paths. Use forward slashes instead.\n"
fi

# Check SKILL.md naming for skill files
if [[ "$FILE_PATH" =~ /skills/ && ! "$FILE_PATH" =~ SKILL\.md$ ]]; then
  if [[ $(basename "$FILE_PATH") != "SKILL.md" ]]; then
    # This is a reference file, not the main skill file - OK
    :
  fi
fi

# Report errors if any
if [[ -n "$ERRORS" ]]; then
  echo "Validation errors in $(basename "$FILE_PATH"):"
  echo -e "$ERRORS"
  echo ""
  echo "Please fix these issues before proceeding."
  exit 2
fi

echo "Validated: $(basename "$FILE_PATH")"
exit 0
