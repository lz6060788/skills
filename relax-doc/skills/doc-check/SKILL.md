---
name: doc-check
description: 渐进式语义分析 skill，执行两阶段过滤（路径匹配 → 语义匹配）来判断代码变更对文档的影响。当需要分析代码变更对文档的影响、分析 git diff 对文档的冲击时使用。
---

# doc-check

## body

### Two-Phase Mechanism

The doc-check skill implements a Progressive Semantic Analysis engine that uses a two-phase mechanism to determine whether code changes impact documentation.

#### Phase 1: Filtering (Low Cost)

The goal of Phase 1 is to avoid loading documents whenever possible. It consists of four filtering levels:

| Level | Filter Type | Description |
|-------|-------------|-------------|
| Level 0 | Path Matching | Filter by code_paths from `docs/graph.json` - hard filter using glob patterns |
| Level 1 | Diff Summary | AI-generated one-liner summarizing the diff |
| Level 2 | Module Summary | Semantic matching against module_summary from `docs/graph.json` |
| Level 3 | Doc Summary | Fine-grained matching against doc.summary fields |

Each level progressively narrows the candidate document set. Documents that fail earlier levels are discarded without loading.

#### Phase 2: Understanding (High Cost)

Only executed for candidate documents that pass Phase 1 filtering:

1. Load document content
2. Compare with diff
3. Make semantic judgment

### Three-State Judgment (certainty)

| certainty | meaning | behavior |
|-----------|---------|----------|
| high | Clear impact - direct relationship between code change and doc content | Auto doc.update |
| medium | Possible impact - indirect or partial relationship | Recommend doc.gen (Augment or Refactor) |
| low | No impact - code change does not affect this document | Ignore |

### Output Structure (Fixed)

```json
{
  "module": "auth",
  "decisions": [
    {
      "doc": "design",
      "decision": "update_required",
      "certainty": "high",
      "reason": "Authentication flow changed (OAuth added)"
    }
  ]
}
```

### Decision Types

- `update_required`: Document needs to be updated based on code changes
- `no_update_required`: Document is not affected by code changes
- `needs_review`: Human judgment needed to determine impact

### Git-History-Based Batch Analysis

Instead of requiring a manually provided diff, doc-check can use `_meta.lastDocSyncRef` from `graph.json` to automatically calculate the diff range for batch analysis.

#### Workflow

```
Step 1: Read _meta.lastDocSyncRef from graph.json
          │
          ├─ Missing → fallback: git log --format="%H" -1 -- docs/
          ├─ Invalid → fallback: git log --format="%H" -1 -- docs/
          └─ Valid   → use as sync ref
          │
Step 2: git diff <ref>..HEAD -- ':(exclude)docs/**'
          │
          ├─ Empty diff → report "no code changes", exit
          └─ Non-empty  → continue
          │
Step 3: Run standard two-phase analysis on the diff
          │
Step 4: Output decisions with sync context
```

#### Fallback Handling

| Condition | Detection | Fallback |
|-----------|-----------|----------|
| `_meta` missing | No `_meta` key in graph.json | `git log --format="%H" -1 -- docs/` |
| `lastDocSyncRef` missing | No `lastDocSyncRef` in `_meta` | `git log --format="%H" -1 -- docs/` |
| Invalid hash | `git cat-file -t <ref>` fails | `git log --format="%H" -1 -- docs/` |
| Unreachable ref | `git merge-base --is-ancestor <ref> HEAD` fails | `git log --format="%H" -1 -- docs/` |

#### Large Diff Warning

Before running the full two-phase analysis, check the diff size:

```bash
# Count changed files and lines
git diff --stat <ref>..HEAD -- ':(exclude)docs/**'
```

| Scale | Changed Files | Changed Lines | Strategy |
|-------|--------------|---------------|----------|
| Small | < 20 | < 500 | Process directly |
| Medium | 20-50 | 500-5000 | Group by directory, process sequentially |
| Large | > 50 | > 5000 | `git diff --stat` first, then selective Level 0 per directory |

For large diffs, warn the user and suggest narrowing the scope or processing incrementally.

## references

- filtering-strategy.md
