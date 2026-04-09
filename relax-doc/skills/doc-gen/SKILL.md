---
name: doc-gen
description: 文档生成与重构 skill，具备改结构、新文档、跨文档的特权。当需要：(1) 初始化新模块文档，(2) 补全缺失内容，(3) 重构混乱文档结构时使用。
---

# doc-gen

## Capabilities

doc-gen is the **Document Structure & Content Construction/Refactoring** capability.

Unlike doc-update which handles small incremental changes, doc-gen has privileges for:
- Creating new documents
- Changing document structure
- Cross-document reorganization

## Three Modes

### 1. Init (初始化)

**Use for:**
- New module documentation
- New document creation

**Output format:**
```md
## Overview
## Architecture
## Flow
```

**Principle:** Structure first, content follows

### 2. Augment (补全)

**Use for:**
- Missing content in existing documents
- Incomplete sections
- Gap filling

**Output format:**
```diff
+ ## OAuth Flow
+ description...
+ - point 1
+ - point 2
```

**Principle:** Additive only, preserve existing content

### 3. Refactor (重构)

**Use for:**
- Messy documentation cleanup
- Structure adjustment
- Content migration
- Cross-document reorganization

**Output format:**
```text
1. New structure suggestion
2. Content migration plan
3. Rewrite specific sections:
   - Section A: new content
   - Section B: merged from X and Y
```

**Principle:** Structure first, then migrate content

## Privileges Table

| Capability | doc.update | doc.gen |
|---|---|---|
| Small changes | Yes | No |
| Add content | Partial | Yes |
| New document | No | Yes |
| Change structure | No | Yes |
| Cross-document work | No | Yes |
| Reorganize & summarize | No | Yes |

## Context Strategy

| Level | Content | When Used |
|---|---|---|
| L1 | Current document | All modes |
| L2 | diff / code context | Augment, Refactor |
| L3 | Same-module docs | Refactor only |

### Context Selection Rules

- **Init mode:** L1 only (new document, no context needed)
- **Augment mode:** L1 + L2 (existing doc + relevant diff/code)
- **Refactor mode:** L1 + L2 + L3 (full context for reorganization)

## Output Formats

### Init Mode Output
```
## Overview
[brief description of the module/document purpose]

## Architecture
[structural components and their relationships]

## Flow
[main processes or data flows]
```

### Augment Mode Output
```diff
+ ## [Missing Section Title]
+ [description]
+ [details]
+ - [point 1]
+ - [point 2]
```

### Refactor Mode Output
```text
# Refactoring Plan

## 1. New Structure
[proposed structure]

## 2. Content Migration
[what goes where]

## 3. Specific Section Rewrites
### Section A
[new content]

### Section B
[new content]
```

## Key Constraints

1. **doc-gen can change structure** (doc-update cannot)
2. **doc-gen can create new documents** (doc-update cannot)
3. **doc-gen can work cross-document** (refactor mode only)
4. **doc-gen can reorganize and summarize** (doc-update cannot)
5. **Avoid small incremental changes** - use doc-update for those

## When to Use doc-gen

- Starting documentation for a new module
- Document has missing/empty sections
- Document structure is confusing or outdated
- Need to merge content from multiple documents
- Creating a new document from scratch

## When NOT to Use doc-gen

- Fixing typos or small wording issues (use doc-update)
- Updating a single sentence
- Making minor content adjustments
- When structure is already good and only content needs updating

## Related Skills

- **doc-update:** For small changes, incremental updates
- **doc-check:** For validating documentation quality
- **doc-evolution:** For tracking documentation lifecycle
- **doc-index:** For managing documentation navigation
