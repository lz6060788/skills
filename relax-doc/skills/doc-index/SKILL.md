---
name: doc-index
description: 索引系统维护 skill，维护 graph.json 和 index.md。当需要：(1) 构建或更新索引，(2) 查询文档状态，(3) 维护文档与代码的映射关系时使用。
---

# Skill: doc-index

## Overview

The doc-index skill manages the semantic documentation index system. It maintains `graph.json` as the central source of truth for documentation mapping, and generates human-readable `index.md` status reports.

## Core Responsibilities

### 1. Build graph.json

`graph.json` is a structured index that maps modules to their code paths and documentation files.

**File location:** `docs/graph.json` (project documentation directory, NOT `.claude/`)

**Companion file:** `docs/index.md` — generated alongside graph.json in the same `docs/` directory.

> **Constraint:** Index files MUST be stored in the project's `docs/` directory. Do NOT create a separate `doc-index/` subdirectory, neither under `.claude/` nor under `docs/`.

**Structure:**
```json
{
  "_meta": {
    "lastDocSyncRef": "9f2ca690b41e11c3"
  },
  "<module_name>": {
    "code_paths": ["glob/pattern/paths"],
    "module_summary": "High-level module description",
    "docs": {
      "<doc_type>": {
        "path": "relative/path/to/doc.md",
        "summary": "Document summary following writing rules",
        "signature": "a1b2c3d4e5f6a7b8"
      }
    }
  }
}
```

### 2. Document Signature

Each doc entry in `graph.json` carries a `signature` field — a truncated SHA-256 hash of the document file content. It serves as a lightweight fingerprint to detect content changes without re-reading the full document.

#### Signature Rules

| Property | Value |
|----------|-------|
| **Algorithm** | SHA-256 |
| **Input** | Full file content (raw bytes) |
| **Output** | First 16 hex characters of the digest |
| **Example** | `"9c50d387e41921e9"` |

#### Computation

```bash
sha256sum <file_path> | cut -c1-16
```

#### When to Compute

| Scenario | Action |
|----------|--------|
| Initial index build | Compute for every doc |
| Adding a new doc entry | Compute for the new doc |
| Running index validation | Recompute and compare |
| Summary is manually updated | Recompute and update |

#### Signature Validation Workflow

```
For each doc entry in graph.json:
  1. Check: does doc.path file exist?
     → NO: mark as :x: (missing)
     → YES: continue

  2. Compute current signature from file content

  3. Compare current signature with stored signature
     → MATCH: document unchanged, summary is current → :white_check_mark:
     → MISMATCH: document content changed, summary may be stale → :warning:

  4. For mismatched docs:
     a. Re-read the document
     b. Determine if summary still accurately reflects content
     c. If summary needs update → regenerate summary + update signature
     d. If summary is still valid → only update signature
```

#### Design Rationale

- **16 chars** is sufficient: collision probability for <1000 docs is negligible
- **Full content hash**: guarantees detection of any edit (heading, paragraph, table)
- **Truncated**: keeps `graph.json` compact and human-readable
- **No mtime/size heuristics**: timestamps are fragile (git checkout, editor save), content hash is deterministic

### 3. Maintain Summaries

All summaries must follow the strict format:

```
[Scope] + [Core Responsibility] + [Key Concepts]
```

**Format:** `Handles [scope] including [concept1], [concept2], and [concept3].`

**Examples:**
- "Handles authentication including credential login, token lifecycle, and OAuth flows."
- "Manages user sessions including session creation, validation, timeout, and termination."
- "Provides API endpoints for resource CRUD operations including filtering, pagination, and error handling."

**Summary Writing Rules:**
- Start with action verb: Handles, Manages, Provides, Manages
- Scope should be the module or component name
- Key concepts should be 2-4 specific items
- Keep summaries under 80 characters
- Do not use vague terms like "and more" or "etc."

### 4. Maintain Sync Metadata

`graph.json` contains a `_meta` field at the top level that tracks the last documentation sync point:

```json
{
  "_meta": {
    "lastDocSyncRef": "9f2ca690b41e11c3"
  }
}
```

#### When to Update

| Scenario | Action |
|----------|--------|
| doc-sync workflow completes | Set `_meta.lastDocSyncRef` to HEAD hash |
| Index is fully rebuilt from scratch | Set `_meta.lastDocSyncRef` to HEAD hash |
| Single doc update (not full sync) | Do NOT update `lastDocSyncRef` |

#### How to Update

```bash
# Get current HEAD hash (16-char short)
HASH=$(git rev-parse --short=16 HEAD)

# Validate the hash is a valid commit
git cat-file -t $HASH  # should output "commit"

# Write to graph.json _meta.lastDocSyncRef
```

#### Fallback Behavior

When `_meta.lastDocSyncRef` is missing or invalid, consumers should fall back to:
```bash
git log --format="%H" -1 -- docs/
```
This finds the last commit that touched any docs/ file.

### 5. Provide Documentation Status View

Generate `index.md` with a human-readable status table:

```md
## Modules

| Module | Design | API | User | Status |
|--------|--------|-----|------|--------|
| auth   | :white_check_mark: | :warning: sig | :white_check_mark: | partial |
```

**Status indicators:**
- :white_check_mark: - Up to date (signature matches)
- :warning: - Needs update (signature mismatch, document changed)
- :x: - Missing (file does not exist)
- :arrow_right: - Link only, no summary

**Module-level status:**
- `up to date` — all docs :white_check_mark:
- `partial` — some docs :warning: or :x:
- `needs attention` — any doc :x:

## Three-Layer Semantic Structure

The index uses three layers for precise documentation lookup:

| Layer | Purpose | Example |
|-------|---------|---------|
| code_paths | Hard filtering - identifies which modules exist in codebase | `"src/modules/auth/**"` |
| module_summary | Module-level semantic matching | "Authentication subsystem responsible for identity verification..." |
| doc.summary | Document-level fine matching | "Describes authentication mechanisms including login flows..." |

**Signature adds a fourth capability: change detection.** It enables validation without loading document content, making the index self-checking.

## Commands

### Build/Update Index
```
Analyze codebase structure
Identify all documented modules
Compute signature for each doc file
Update graph.json with current code paths, summaries, and signatures
Generate index.md status view
```

### Validate Index
```
Read graph.json
For each doc entry:
  - Verify doc.path file exists
  - Compute current signature
  - Compare with stored signature
  - Flag mismatches
Report validation results
```

### Query Documentation Status
```
Read graph.json
Run validation (signature comparison)
Generate status table for index.md
```

## Files Managed

- **`docs/graph.json`** - Machine-readable semantic index (source of truth)
- **`docs/index.md`** - Human-readable status report (generated)

> Both files reside directly in the project's `docs/` directory. No subdirectory is created.

## Usage Guidelines

1. **When to invoke doc-index:**
   - Building initial documentation index
   - Adding new module documentation
   - Updating existing documentation
   - Validating index freshness (signature-based)
   - Before committing documentation changes

2. **Workflow:**
   - Always read current `graph.json` first
   - Compute signatures for all indexed docs
   - Compare signatures to detect stale entries
   - Make changes incrementally
   - Validate JSON syntax after edits
   - Regenerate `index.md` after any `graph.json` change

3. **Validation (signature-based):**
   - Ensure all `code_paths` globs match actual files
   - Verify `doc.path` files exist
   - **Recompute `doc.signature` and compare** — mismatch means doc changed
   - If signature mismatch: re-read doc, update summary if needed, update signature
   - Confirm summaries follow writing rules
