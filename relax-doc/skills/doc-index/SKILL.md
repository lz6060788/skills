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

**File location:** Project root or `.claude/doc-index/graph.json`

**Structure:**
```json
{
  "<module_name>": {
    "code_paths": ["glob/pattern/paths"],
    "module_summary": "High-level module description",
    "docs": {
      "<doc_type>": {
        "path": "relative/path/to/doc.md",
        "summary": "Document summary following writing rules"
      }
    }
  }
}
```

### 2. Maintain Summaries

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

### 3. Provide Documentation Status View

Generate `index.md` with a human-readable status table:

```md
## Modules

| Module | Design | API | User | Status |
|--------|--------|-----|------|--------|
| auth   | :warning: outdated | :warning: | :white_check_mark: | needs update |
```

**Status indicators:**
- :white_check_mark: - Up to date
- :warning: - Needs update or outdated
- :x: - Missing
- :arrow_right: - Link only, no summary

## Three-Layer Semantic Structure

The index uses three layers for precise documentation lookup:

| Layer | Purpose | Example |
|-------|---------|---------|
| code_paths | Hard filtering - identifies which modules exist in codebase | `"src/modules/auth/**"` |
| module_summary | Module-level semantic matching | "Authentication subsystem responsible for identity verification..." |
| doc.summary | Document-level fine matching | "Describes authentication mechanisms including login flows..." |

## Commands

### Build/Update Index
```
Analyze codebase structure
Identify all documented modules
Update graph.json with current code paths
Refresh all summaries
Generate index.md status view
```

### Query Documentation Status
```
Read graph.json
Compare doc paths against actual files
Report status for each module and doc type
```

## Files Managed

- **graph.json** - Machine-readable semantic index (source of truth)
- **index.md** - Human-readable status report (generated)

## Usage Guidelines

1. **When to invoke doc-index:**
   - Building initial documentation index
   - Adding new module documentation
   - Updating existing documentation
   - Checking documentation coverage
   - Before committing documentation changes

2. **Workflow:**
   - Always read current `graph.json` first
   - Make changes incrementally
   - Validate JSON syntax after edits
   - Regenerate `index.md` after any `graph.json` change

3. **Validation:**
   - Ensure all `code_paths` globs match actual files
   - Verify `doc.path` files exist
   - Confirm summaries follow writing rules
