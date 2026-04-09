# Update Strategies Reference

## Overview

Different document types require different update strategies to maintain integrity and purpose.

## Document Types and Strategies

### Design Documents (`design`)

**Strategy: `modify`**

Design documents describe the architecture, components, and decisions of a system. They evolve with the system and require active modification.

#### When to Modify
- Adding new components or modules
- Updating architecture decisions
- Changing component relationships
- Reflecting new design patterns
- Updating API contracts between modules

#### When NOT to Modify
- Never delete architectural decisions that are still relevant
- Never remove chapters describing existing structure
- Never reorder established document structure

#### Best Practices
- Maintain backward compatibility in documentation
- Preserve decision rationale
- Keep terminology consistent with existing content
- Follow existing heading hierarchy

### API Documents (`api`)

**Strategy: `safe` (append new)**

API documentation describes interfaces and their contracts. New endpoints or parameters should be added without modifying existing documentation.

#### When to Append
- Adding new API endpoints
- Adding new request/response parameters
- Adding new error codes
- Adding new authentication methods

#### When NOT to Modify
- Never modify existing endpoint descriptions
- Never change parameter definitions for existing endpoints
- Never alter example requests/responses
- Never update error code meanings

#### Best Practices
- Add new sections at the end of relevant chapters
- Use "Added in vX.X.X" markers for new items
- Maintain consistent formatting with existing content
- Follow original terminology

### User Documents (`user`)

**Strategy: `safe`**

User documentation helps users accomplish tasks. New content can be added, but existing how-to guides and tutorials must remain stable.

#### When to Append
- Adding new usage scenarios
- Adding new examples
- Adding new FAQs
- Adding new troubleshooting items

#### When NOT to Modify
- Never modify step-by-step tutorials
- Never change example values in working examples
- Never alter troubleshooting procedures that work
- Never update screenshots (mark as outdated instead)

#### Best Practices
- Clearly mark new content additions
- Add "What's New" sections for recent changes
- Maintain consistent voice and tone
- Follow original formatting conventions

## Update Decision Matrix

| Situation | design | api | user |
|-----------|--------|-----|------|
| Add new feature | modify | append new | append new |
| Fix typo in description | modify | **never** | **never** |
| Clarify ambiguous text | modify | **never** | **never** |
| Add missing parameter | modify | append new | **never** |
| Add new example | modify | append new | append new |
| Update deprecated info | modify | append new | append new |

## Patch-Level Modification Guidelines

### Minimal Context Rule
Always use the minimum context necessary to make the change:

1. Load only the document being modified
2. Load only the specific section being changed
3. Load only relevant code snippets (if needed)

### Change Size Limits
- Single patch: Should affect no more than 1-3 sections
- Large changes: Break into multiple smaller patches
- Structural changes: Require explicit user approval

### Diff Quality Standards
- Diffs must be atomic (one logical change per diff)
- Include context lines showing surrounding content
- Use proper diff headers to identify sections
- Preserve indentation and formatting

## Conflict Resolution

When updates conflict with existing content:

1. **Design docs**: Reconcile by preserving both perspectives, marking one as "updated approach"
2. **API docs**: Never reconcile; always append as new
3. **User docs**: Never reconcile; always append as new

## Version Considerations

### Backward Compatibility
- Design: May need to describe migration paths
- API: Must indicate breaking vs non-breaking changes
- User: Should maintain guide for previous versions

### Deprecation Notices
- Use consistent deprecation markers
- Include version numbers for when items were deprecated
- Provide migration guidance where applicable
