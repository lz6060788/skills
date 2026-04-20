#!/bin/bash
# pre-commit-check.sh
# Claude Code UserPromptSubmit hook
# Detects commit-related prompts with code changes, injects directive context
# via additionalContext to enforce doc-check before git commit.

# Read stdin JSON
input=$(cat)

# Extract prompt field
prompt=$(echo "$input" | grep -o '"prompt":"[^"]*"' | sed 's/"prompt":"//;s/"$//')

# Check for commit-related keywords
if echo "$prompt" | grep -qiE "(commit|提交|git push|git add)"; then
    cd "$CLAUDE_PROJECT_DIR" || exit 0

    # Get git diff stats
    diff_output=$(git diff --stat 2>/dev/null)
    diff_staged=$(git diff --staged --stat 2>/dev/null)

    if [ -n "$diff_output" ] || [ -n "$diff_staged" ]; then
        # Build change summary with escaped newlines
        changes=""
        if [ -n "$diff_staged" ]; then
            changes="Staged changes: $(echo "$diff_staged" | tr '\n' ' ')"
        fi
        if [ -n "$diff_output" ]; then
            if [ -n "$changes" ]; then
                changes="$changes. Unstaged changes: $(echo "$diff_output" | tr '\n' ' ')"
            else
                changes="Unstaged changes: $(echo "$diff_output" | tr '\n' ' ')"
            fi
        fi

        # Output JSON with additionalContext
        # Use printf with escaped newlines; diff content is single-line via tr
        printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"<doc-check-enforcement>\\n=== Doc-Check: Commit before doc sync ===\\n\\nCode changes detected: %s.\\n\\nIMPORTANT: Before executing git commit, you MUST complete these steps IN ORDER:\\n\\n1. Use the doc-check skill to analyze which documents are affected by the code changes\\n2. If doc-check finds documents that need updating (certainty=high):\\n   a. Use doc-update skill to update those documents\\n   b. Use doc-index skill to refresh graph.json signatures\\n   c. Stage the updated documentation files alongside the code changes\\n3. If doc-check finds documents that need review (certainty=medium):\\n   a. Report them to the user and ask whether to update before committing\\n4. Only AFTER documentation is synchronized, proceed with git commit\\n\\nDo NOT skip the doc-check step. This is enforced by the UserPromptSubmit hook.\\n</doc-check-enforcement>"}}' "$changes"

        exit 0
    fi
fi

exit 0
