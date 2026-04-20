# Filtering Strategy

## Overview

The filtering strategy is the core of the doc-check skill's efficiency. It implements a four-level progressive filtering mechanism designed to minimize document loading while accurately identifying documents affected by code changes.

## The Three-Layer Semantic Structure

Before diving into the filtering levels, it is important to understand the three-layer semantic structure that underlies the `docs/graph.json` data model:

| Layer | Purpose | Data Source |
|-------|---------|-------------|
| code_paths | Hard filtering - definitive path-based inclusion/exclusion | glob patterns in `docs/graph.json` |
| module_summary | Module-level semantic matching | text description of module responsibility |
| doc.summary | Document-level fine-grained matching | text description of specific document content |

## Level-by-Level Filtering Algorithm

### Level 0: Path Matching (code_paths)

**Purpose**: Definitive hard filter using glob patterns

**Process**:
1. Extract all `code_paths` from `docs/graph.json` for the relevant module
2. For each changed file in the diff, test against each glob pattern
3. If any changed file matches any `code_paths` pattern, the module is considered relevant
4. If no files match, discard the entire module (no further levels executed)

**Example**:
```json
// graph.json
{
  "auth": {
    "code_paths": ["src/modules/auth/**", "src/utils/jwt.ts"]
  }
}
```

**Why it works**: Path matching is a fast, deterministic operation that does not require semantic understanding. It provides an immediate coarse-grained filter.

### Level 1: Diff Summary

**Purpose**: Generate an AI-powered one-line summary of the code changes

**Process**:
1. Take the full diff of changed files
2. Generate a concise one-line summary describing the nature of the change
3. This summary is used in subsequent levels for semantic matching

**Example output**:
```
"Added OAuth2 authentication flow with Google and GitHub providers"
```

**Why it works**: The summary abstracts away implementation details while capturing the semantic intent of the change.

### Level 2: Module Summary Semantic Matching

**Purpose**: Determine if the diff is semantically related to the module's core responsibility

**Process**:
1. Retrieve `module_summary` from `docs/graph.json` for the candidate module
2. Compare the diff summary (from Level 1) against the module_summary
3. Use semantic similarity to score the relationship
4. If similarity is above threshold, proceed to Level 3
5. If similarity is below threshold, mark as `low` certainty (no impact)

**Example**:
```json
// graph.json
"module_summary": "Authentication subsystem responsible for identity verification, token lifecycle, and OAuth integration."
```

**Scoring criteria**:
- High similarity: diff involves core responsibilities (e.g., "OAuth", "token", "login")
- Low similarity: diff is peripheral to module (e.g., refactoring internal helper functions)
- No similarity: diff is unrelated

### Level 3: Doc Summary Fine-Grained Matching

**Purpose**: Identify which specific documents within the module are affected

**Process**:
1. For each document type in the module (design, api, user, etc.)
2. Retrieve the `doc.summary` field from `docs/graph.json`
3. Compare the diff summary against each doc.summary
4. Calculate per-document impact scores

**Example**:
```json
// graph.json
"docs": {
  "design": {
    "path": "docs/design/modules/auth/index.md",
    "summary": "Describes authentication mechanisms including login flows, token lifecycle, and OAuth integration."
  },
  "api": {
    "path": "docs/api/rest/auth.md",
    "summary": "Defines authentication endpoints such as login, logout, token refresh, and OAuth callbacks."
  }
}
```

**Scoring criteria**:
- `high` certainty: diff directly modifies features described in doc.summary
- `medium` certainty: diff affects related but not central aspects
- `low` certainty: diff does not affect content described in doc.summary

## Decision Matrix

| Level 2 Result | Level 3 Result | Final Certainty | Decision |
|-----------------|----------------|-----------------|----------|
| Unrelated | N/A | low | no_update_required |
| Related - core | Not matched | medium | needs_review |
| Related - core | Matched | high | update_required |
| Related - peripheral | Matched | medium | needs_review |
| Related - peripheral | Not matched | low | no_update_required |

## Phase Transition: Phase 1 to Phase 2

Phase 1 (Filtering) ends when:
- All modules have been evaluated, OR
- A candidate document set has been identified

Candidate documents are those that:
1. Passed Level 0 (path matching)
2. Passed Level 2 (module summary semantic matching with sufficient similarity)

Phase 2 (Understanding) begins with:
- Loading document content for each candidate document
- Comparing diff against actual document content
- Making final semantic judgments

## Cost Optimization Principles

1. **Fail Fast**: Earlier levels use simpler, faster operations. Documents are discarded at the earliest possible level.

2. **No Unnecessary Loading**: A document should never be loaded unless it has a reasonable chance of being affected.

3. **Cumulative Filtering**: Each level builds on the previous level's filtering, exponentially reducing candidates.

4. **Semantic Over Syntactic**: Higher levels use semantic understanding rather than syntactic pattern matching, enabling more accurate filtering.

## Threshold Guidelines

- **Level 2 threshold** (module summary): Recommend similarity score >= 0.6 for proceeding to Level 3
- **Level 3 threshold** (doc summary): Recommend similarity score >= 0.7 for high certainty

These thresholds can be adjusted based on:
- Size of the codebase
- Number of documents
- Tolerance for missed updates (recall) vs false positives (precision)

## Git-History Batch Mode Considerations

When using git-history-based batch analysis (via `_meta.lastDocSyncRef`), the filtering strategy operates with some key differences:

### Pre-filtering by Diff Scope

The `git diff <ref>..HEAD -- ':(exclude)docs/**'` command already excludes documentation files from the diff. This means:

- **Level 0 (Path Matching)** remains fully valid and is the primary filter for narrowing which modules are affected
- The input to Level 0 is already scoped to code-only changes, reducing noise
- Modules with `code_paths: []` (e.g., plans, integration) will always be excluded from batch analysis since they have no code to diff against

### Large Diff Handling Strategy

| Scale | Files Changed | Strategy |
|-------|--------------|----------|
| Small | < 20 files | Process directly — run Level 0 through Level 3 on the full diff |
| Medium | 20-50 files | Group changed files by top-level directory, process each group sequentially to control context window usage |
| Large | > 50 files | Run `git diff --stat` first to identify hotspots, then apply Level 0 per directory before combining results |

### Batch-Specific Optimizations

1. **Directory-level grouping**: For medium/large diffs, group files by their parent directory before Level 0 matching. This allows batch-matching against `code_paths` globs more efficiently.

2. **Commits within range**: Use `git log --oneline <ref>..HEAD -- ':(exclude)docs/**'` to provide a summary of code changes for the diff summary (Level 1), giving broader context than a single diff.

3. **Skip non-code modules**: Modules with empty `code_paths` can be immediately skipped in batch mode since they have no code footprint to match against.
