# Document Generation Modes - Detailed Specification

This document provides detailed specifications and examples for each of the three doc-gen modes.

---

## Mode 1: Init (初始化)

### Purpose
Create new documentation from scratch for new modules or new documents.

### Trigger Conditions
- New module requires documentation
- New document within existing module
- No existing documentation exists
- Starting fresh for a new feature/component

### Output Structure
```md
## Overview
[What this module/document is about - 1-3 sentences]

## Architecture
[Components, their roles, and relationships - bullet points or short paragraphs]

## Flow
[Main processes, data flows, or user flows - sequential or flowchart style]
```

### Example

**Input:** New "Auth" module needs documentation

**Output:**
```md
## Overview
The Auth module handles user authentication and session management for the application.

## Architecture
- **AuthService**: Core authentication logic
- **TokenManager**: JWT token generation and validation
- **SessionStore**: User session persistence
- **AuthController**: HTTP endpoint definitions

## Flow
1. User submits credentials via `/api/auth/login`
2. AuthService validates credentials against user store
3. TokenManager generates JWT with user claims
4. SessionStore creates session record
5. JWT returned to client for subsequent requests
```

### Key Principles
1. **Structure first, content follows** - Don't write detailed content before structure is defined
2. **Keep it high-level** - Init mode creates skeleton, not final content
3. **Use bullet points** - They're easier to expand than paragraphs
4. **Label components** - Use bold for key terms that will be defined later

---

## Mode 2: Augment (补全)

### Purpose
Fill in missing content within existing documentation.

### Trigger Conditions
- Existing document has empty or placeholder sections
- New content needs to be added to incomplete documentation
- Documentation has "TODO" or "TBD" markers
- Feature was implemented but never documented

### Output Structure
```diff
+ ## [Section Title]
+ [Description paragraph explaining the section]
+
+ [Additional details]
+ - [Point 1]
+ - [Point 2]
+ - [Point 3]
```

### Example

**Input:** Existing Auth docs missing "OAuth Flow" section

**Output:**
```diff
+ ## OAuth Flow
+ The module supports OAuth 2.0 authentication with external identity providers.
+
+ Supported providers: Google, GitHub, Microsoft
+
+ Flow details:
+ - User clicks "Login with {Provider}" button
+ - Application redirects to provider's authorization page
+ - User grants permissions
+ - Provider redirects back with authorization code
+ - Application exchanges code for access token
+ - User info fetched and session created
```

### Key Principles
1. **Additive only** - Never modify or remove existing content
2. **Match existing style** - Follow the tone and format of surrounding content
3. **Provide context** - Explain not just what, but why
4. **Include examples** - Code snippets, flows, or use cases when relevant

---

## Mode 3: Refactor (重构)

### Purpose
Reorganize, restructure, or rewrite existing documentation that has become messy, outdated, or poorly organized.

### Trigger Conditions
- Document structure is confusing
- Content is duplicated across sections
- Cross-cutting concerns need reorganization
- Documentation needs to be split or merged
- Structure doesn't match current code architecture
- Multiple related documents need consolidation

### Output Structure
```text
# Refactoring Plan: [Document Name]

## 1. New Structure Proposal
[Proposed document structure with rationale]

## 2. Content Migration Plan
[Where each piece of content will go]

## 3. Specific Section Rewrites
### [Section A]
[Rewritten content]

### [Section B]
[Rewritten content]

## 4. Content to Archive
[Old content that is no longer relevant]
```

### Example

**Input:** Messy API documentation with duplicated content

**Output:**
```text
# Refactoring Plan: API Documentation

## 1. New Structure Proposal
- Split into separate documents per resource
- Create master index with navigation
- Move authentication details to separate guide
- Consolidate error handling into common section

Rationale: Current document exceeds 2000 lines, hard to navigate

## 2. Content Migration Plan
| Old Location | New Location |
|---|---|
| Auth section | /api/guides/authentication.md |
| Rate limiting | /api/guides/rate-limits.md |
| User endpoints | /api/resources/users.md |
| Order endpoints | /api/resources/orders.md |

## 3. Specific Section Rewrites

### Authentication Section
**Old:** Mixed auth concepts with endpoint details
**New:**
```md
# Authentication Guide

## Overview
All API requests require authentication via...

## Methods
- API Key (for server-to-server)
- OAuth 2.0 (for user-authorized access)

## Quick Start
[5-step quick start guide]
```

### User Endpoints Section
**Old:** 500 lines, mixed GET/POST/PUT/DELETE
**New:** Split into separate subsections by operation type

## 4. Content to Archive
- Legacy v1 endpoint documentation (superseded)
- Deprecated authentication methods
```

### Key Principles
1. **Analyze before changing** - Understand current structure problems
2. **Structure first** - Define new structure before writing content
3. **Plan migration** - Show where content moves, don't just delete
4. **Maintain continuity** - Ensure readers can still find information
5. **Archive don't delete** - Move old content to archive, don't lose it

---

## Mode Comparison Quick Reference

| Aspect | Init | Augment | Refactor |
|---|---|---|---|
| Creates new doc | Yes | No | Can split/merge |
| Adds content | Yes (new) | Yes (missing) | Rewrites |
| Changes structure | Yes | No | Yes |
| Cross-document | No | No | Yes |
| Content removal | No | No | Yes (archive) |
| Context needed | L1 | L1 + L2 | L1 + L2 + L3 |

---

## Decision Tree: Which Mode to Use?

```
Is there existing documentation?
|
+-- No --> Use INIT mode
|
+-- Yes --> Does it have missing/empty sections?
    |
    +-- Yes --> Use AUGMENT mode
    |
    +-- No --> Is the structure confusing or outdated?
        |
        +-- Yes --> Use REFACTOR mode
        |
        +-- No --> Use doc-update for small changes
```

---

## Anti-Patterns (When NOT to use each mode)

### Init Anti-Patterns
- Don't use Init when doc-update would suffice
- Don't create elaborate initial structure for small modules
- Don't write detailed content in Init - that's for later phases

### Augment Anti-Patterns
- Don't use Augment to rewrite entire sections
- Don't use Augment when the real issue is structural
- Don't add content that contradicts existing structure

### Refactor Anti-Patterns
- Don't use Refactor for small incremental changes
- Don't skip the migration plan - readers need to understand changes
- Don't refactor without understanding the full context (L3)
- Don't delete content - archive it
