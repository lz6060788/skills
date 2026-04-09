# doc-update Skill

## Name
doc-update

## Description
最小上下文文档更新 skill，执行 patch 级修改。当需要更新文档、对文档进行增量修改、根据代码变更调整文档内容时使用。

## Core Principles
doc.update = single document, minimal context, patch-level modification

## Input Structure

```json
{
  "doc_path": "...",
  "doc_type": "design",
  "diff_summary": "...",
  "reason": "...",
  "relevant_code": "..."
}
```

### Fields
- **doc_path** (required): Path to the document to update
- **doc_type** (required): Type of document - `design`, `api`, or `user`
- **diff_summary** (required): Summary of changes to apply
- **reason** (required): Why this change is needed
- **relevant_code** (optional): Minimal code snippets relevant to the change

## Context Constraints

### Only Load
- Current document (required)
- Diff (required)
- Minimal relevant code (optional)
- Index metadata (minimal)

### Forbidden to Load
- Other module documents
- Global context
- Entire repo

## Output Format (Required)

All updates MUST be presented in diff format:

```diff
## Authentication Flow

+ ### OAuth Login
+ - Redirect to provider
+ - Handle callback
```

## Update Strategies

| doc type | default strategy |
|---|---|
| design | modify |
| api | safe (append new) |
| user | safe |

### Strategy Definitions

- **modify**: Modify existing content, add new sections, or update current sections
- **safe**: Append new content only; never modify existing content
- **append new**: Add new sections at appropriate locations without modifying existing

## Behavior Modes

### Auto-trigger
If certainty == high, auto-execute the update.

### User-trigger
Manual invocation via:
```
claude skill doc.update <doc_path> <doc_type>
```

## Key Constraints

1. **No full rewrites**: Only apply the specific changes requested
2. **Don't break structure**: Maintain existing document structure
3. **Prefer modifying existing sections**: When possible, update existing content rather than adding new
4. **Structure lock**: AI cannot delete chapters or reorder structure
5. **Style inheritance**: Must follow original terminology, heading hierarchy, and expression style

## Usage Examples

### Update a design document
```
claude skill doc.update auth design
```

### Update an API document
```
claude skill doc.update api REST
```

### Update a user guide
```
claude skill doc.update user getting-started
```

## Workflow

1. Load only the specified document and required context
2. Analyze the diff_summary and reason
3. Identify the minimal changes needed
4. Apply changes using the appropriate strategy for doc_type
5. Output the changes in diff format
6. Present only the patch-level modifications, no full rewrites
