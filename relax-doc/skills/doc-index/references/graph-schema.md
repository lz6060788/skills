# Graph Schema Reference

This document defines the complete schema for `graph.json` and guidelines for writing effective summaries.

## graph.json Overview

`graph.json` is the central index that maps code modules to their documentation. It provides a semantic layer for understanding documentation structure and enables automated status reporting.

## Complete Schema

```json
{
  "$schema": "doc-index/graph-schema",
  "version": "1.0",
  "modules": {
    "<module_name>": {
      "code_paths": ["string"],
      "module_summary": "string",
      "docs": {
        "<doc_type>": {
          "path": "string",
          "summary": "string",
          "status": "up_to_date | outdated | missing | link_only"
        }
      }
    }
  }
}
```

### Field Specifications

#### modules
- **Type:** Object
- **Required:** Yes
- **Description:** Container for all module entries

#### module_name (key)
- **Type:** String
- **Required:** Yes
- **Pattern:** `^[a-z][a-z0-9-]*$`
- **Examples:** `auth`, `user-management`, `api-gateway`

#### code_paths
- **Type:** Array of strings
- **Required:** Yes
- **Description:** Glob patterns matching source code files for this module
- **Examples:**
  ```json
  ["src/modules/auth/**"]
  ["src/auth/**/*.ts", "lib/auth/*.js"]
  ["**/auth*.go"]
  ```

#### module_summary
- **Type:** String
- **Required:** Yes
- **Max Length:** 200 characters
- **Format:** `[Scope] + [Core Responsibility] + [Key Concepts]`

#### docs
- **Type:** Object
- **Required:** Yes
- **Description:** Container for all documentation entries for this module

#### doc_type (key)
- **Type:** String
- **Required:** Yes
- **Allowed Values:** `design`, `api`, `user`, `internal`, `operations`, `tutorials`
- **Description:** Categorizes the documentation type

#### docs[doc_type]
- **Type:** Object
- **Required:** Yes

#### docs[doc_type].path
- **Type:** String
- **Required:** Yes
- **Format:** Relative path from project root
- **Examples:**
  ```json
  "path": "docs/design/modules/auth/index.md"
  "path": "docs/api/rest/auth.md"
  "path": "docs/user/auth.md"
  ```

#### docs[doc_type].summary
- **Type:** String
- **Required:** Yes
- **Max Length:** 120 characters
- **Format:** `[Action] + [Scope] + [Key Concepts]`

#### docs[doc_type].status
- **Type:** String
- **Required:** No (defaults to "up_to_date")
- **Allowed Values:**
  - `up_to_date` - Documentation matches current implementation
  - `outdated` - Implementation has changed since documentation was written
  - `missing` - Documentation file does not exist
  - `link_only` - Only a link exists, no substantive content

## Complete Example

```json
{
  "auth": {
    "code_paths": ["src/modules/auth/**"],
    "module_summary": "Authentication subsystem responsible for identity verification, token lifecycle, and OAuth integration.",
    "docs": {
      "design": {
        "path": "docs/design/modules/auth/index.md",
        "summary": "Describes authentication mechanisms including login flows, token lifecycle, and OAuth integration."
      },
      "api": {
        "path": "docs/api/rest/auth.md",
        "summary": "Defines authentication endpoints such as login, logout, token refresh, and OAuth callbacks."
      },
      "user": {
        "path": "docs/user/auth.md",
        "summary": "Explains how users sign in, manage sessions, and use third-party login options."
      }
    }
  },
  "payments": {
    "code_paths": ["src/modules/payments/**", "src/billing/**"],
    "module_summary": "Payment processing subsystem handling transactions, refunds, subscriptions, and payment method management.",
    "docs": {
      "design": {
        "path": "docs/design/modules/payments/index.md",
        "summary": "Explains payment architecture including transaction flow, refund handling, and subscription billing."
      },
      "api": {
        "path": "docs/api/rest/payments.md",
        "summary": "Documents payment endpoints for charging, refunds, subscriptions, and payment method operations."
      },
      "user": {
        "path": "docs/user/payments.md",
        "summary": "Guides users through payment setup, transaction history, and refund requests."
      }
    }
  }
}
```

## Summary Writing Guidelines

### Strong Constraints

All summaries MUST follow this format:

```
[Action Verb] + [Scope] + [Key Concepts]
```

### Format Template

```
[Action] [scope] including [concept1], [concept2], and [concept3].
```

### Action Verbs

Choose the appropriate verb based on the document type:

| Document Type | Recommended Verbs |
|---------------|-------------------|
| design | Describes, Explains, Covers |
| api | Documents, Defines, Specifies |
| user | Explains, Guides, Describes |
| internal | Details, Covers, Documents |
| operations | Describes, Covers, Details |
| tutorials | Teaches, Guides, Walks through |

### Key Concept Selection

- Select 2-4 specific, concrete concepts
- Avoid vague terms: "etc.", "and more", "various"
- Use consistent terminology with code
- Order by importance or logical flow

### Examples by Document Type

**Design Documents:**
```
Describes authentication mechanisms including login flows, token lifecycle, and OAuth integration.
Explains payment architecture including transaction processing, escrow handling, and refund workflows.
Covers notification system design including message queuing, delivery guarantees, and retry logic.
```

**API Documents:**
```
Defines authentication endpoints for login, logout, token refresh, and OAuth callbacks.
Documents user management endpoints including CRUD operations, profile updates, and avatar upload.
Specifies billing endpoints for charges, refunds, subscription management, and invoice generation.
```

**User Documents:**
```
Explains how users sign in, manage sessions, enable MFA, and recover passwords.
Guides users through payment method addition, transaction history, and dispute filing.
Describes how to create projects, invite team members, and manage access permissions.
```

### Common Mistakes

**Incorrect (too vague):**
```
"Handles authentication and stuff."
"Covers user management and more."
"Documents the API endpoints."
```

**Correct (specific and clear):**
```
"Handles authentication including credential login, token refresh, and OAuth flows."
"Covers user management including profile updates, password changes, and session management."
"Documents API endpoints for user CRUD operations, search, filtering, and pagination."
```

## Status Reporting

### Status Calculation Logic

| Condition | Status |
|-----------|--------|
| File exists + summary is current + matches code | `up_to_date` |
| File exists + but code has changed significantly | `outdated` |
| Path exists in graph.json but file missing | `missing` |
| Only link/placeholder content | `link_only` |

### index.md Output Format

```md
## Modules

| Module | Design | API | User | Status |
|--------|--------|-----|------|--------|
| auth   | :white_check_mark: | :white_check_mark: | :white_check_mark: | all up to date |
| billing | :warning: outdated | :white_check_mark: | :x: missing | needs attention |
| notify | :white_check_mark: | :warning: outdated | :white_check_mark: | partial update |
```

### Status Emoji Mapping

| Status | Emoji | Meaning |
|--------|-------|---------|
| up_to_date | :white_check_mark: | Documentation is current |
| outdated | :warning: | Documentation needs update |
| missing | :x: | Documentation not found |
| link_only | :arrow_right: | Only placeholder exists |
