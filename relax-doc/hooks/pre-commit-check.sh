#!/bin/bash
# pre-commit-check.sh
# Claude Code UserPromptSubmit hook
# 检测提交代码时自动运行 doc-check

# 读取 stdin JSON
input=$(cat)

# 解析 prompt 字段
prompt=$(echo "$input" | grep -o '"prompt":"[^"]*"' | sed 's/"prompt":"//;s/"$//')

# 检查是否包含 commit 相关关键词
if echo "$prompt" | grep -qiE "(commit|提交|git push|git add)"; then
    cd "$CLAUDE_PROJECT_DIR" || exit 0

    # 获取 git diff
    diff_output=$(git diff --stat 2>/dev/null)
    diff_staged=$(git diff --staged --stat 2>/dev/null)

    if [ -n "$diff_output" ] || [ -n "$diff_staged" ]; then
        echo ""
        echo "=== Doc-Check: 检测到代码变更 ==="
        echo ""
        if [ -n "$diff_staged" ]; then
            echo "已暂存的变更:"
            echo "$diff_staged"
            echo ""
        fi
        if [ -n "$diff_output" ]; then
            echo "未暂存的变更:"
            echo "$diff_output"
            echo ""
        fi
        echo "建议: 运行 doc-check skill 分析文档更新需求"
        echo ""
    fi
fi

exit 0
