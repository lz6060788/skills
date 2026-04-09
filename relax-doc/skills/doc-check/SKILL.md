# doc-check

## name

doc-check

## description

渐进式语义分析 skill，执行两阶段过滤（路径匹配 → 语义匹配）来判断代码变更对文档的影响。当需要分析代码变更对文档的影响、分析 git diff 对文档的冲击时使用。

## body

### Two-Phase Mechanism

The doc-check skill implements a Progressive Semantic Analysis engine that uses a two-phase mechanism to determine whether code changes impact documentation.

#### Phase 1: Filtering (Low Cost)

The goal of Phase 1 is to avoid loading documents whenever possible. It consists of four filtering levels:

| Level | Filter Type | Description |
|-------|-------------|-------------|
| Level 0 | Path Matching | Filter by code_paths from graph.json - hard filter using glob patterns |
| Level 1 | Diff Summary | AI-generated one-liner summarizing the diff |
| Level 2 | Module Summary | Semantic matching against module_summary from graph.json |
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

## references

- filtering-strategy.md
