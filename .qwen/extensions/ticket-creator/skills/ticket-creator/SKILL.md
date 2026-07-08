---
name: ticket-creator
description: Auto-detect ticket types (Feature, Request, Bug, Issue, Refactor) from user messages and create structured ticket .md files in the .qwen/ directory.
---

# Ticket Creator Skill

You are a ticket creation assistant. When the user describes something that is a Feature, Request, Bug, Issue, or Refactor, you MUST create a structured ticket file in the appropriate `.qwen/` subdirectory.

## Trigger Detection

Detect the ticket type from the user's message using these keywords:

| Type | Trigger Keywords |
|------|-----------------|
| **Feature** | "feature", "new feature", "add feature", "implement", "build", "create", "develop", "new functionality", "capability" |
| **Request** | "request", "need", "want", "please add", "can you add", "it would be nice", "suggestion", "enhancement request" |
| **Bug** | "bug", "broken", "error", "crash", "exception", "not working", "fails", "regression", "fix this", "something is wrong" |
| **Issue** | "issue", "problem", "doesn't work", "won't load", "can't", "unable to", "fails to", "unexpected behavior", "glitch" |
| **Refactor** | "refactor", "clean up", "restructure", "reorganize", "simplify", "code smell", "technical debt", "rewrite", "modernize" |

When the user's message matches multiple types, use the **most specific** one. If ambiguous, ask the user to clarify which type.

## Directory Mapping

| Ticket Type | Directory | Title Prefix |
|------------|-----------|-------------|
| Feature | `.qwen/feature/` | `# Feature: {Title}` |
| Request | `.qwen/feature/` | `# Feature Request: {Title}` |
| Bug | `.qwen/bugs/` | `# BUG-{NNN}: {Title}` |
| Issue | `.qwen/bugs/` | `# ISSUE-{NNN}: {Title}` |
| Refactor | `.qwen/vault/` | `# Refactor: {Title}` |

## Ticket Numbering

1. List all `.md` files in the target directory
2. Find the highest existing `NNN` number (extract the leading 3-digit number from filenames)
3. Increment by 1, zero-pad to 3 digits (e.g., `005`, `010`)
4. If the directory is empty, start at `001`

## Filename Convention

Format: `{NNN}-{descriptive-slug}.md`

- Slug: lowercase, hyphens for spaces, max ~50 chars
- Examples: `003-user-avatar-upload.md`, `005-login-timeout-fix.md`

## Ticket Templates

### Feature

```markdown
# Feature: {Title}

## Overview
{Description of the feature and its purpose}

---

## Requirements
- {Requirement 1}
- {Requirement 2}

## Implementation Notes
- {Technical notes, approach, dependencies}

## Acceptance Criteria
- [ ] {Criterion 1}
- [ ] {Criterion 2}
```

### Bug

```markdown
# BUG-{NNN}: {Title}

**Status:** Open
**Severity:** {Critical | High | Medium | Low}
**Reported:** {YYYY-MM-DD}
**URL:** {URL if applicable}

---

## Description
{What is broken and how it manifests}

## Steps to Reproduce
1. {Step 1}
2. {Step 2}
3. {Step 3}

## Expected Behavior
{What should happen}

## Actual Behavior
{What actually happens}

## Root Cause
{If known, the root cause analysis}

## Impact
{Who/what is affected and how}

## Fix
{Proposed or implemented fix}

## Verification
{How to verify the fix works}

## Notes
{Any additional context}
```

### Request

```markdown
# Feature Request: {Title}

**Status:** Open
**Priority:** {High | Medium | Low}
**Requested:** {YYYY-MM-DD}

---

## Summary
{One-paragraph description of what is being requested}

## Motivation
{Why this is needed — user pain point, business value}

## Proposed Solution
{How this could be implemented}

## Alternatives Considered
{Other approaches that were evaluated}

## Additional Context
{Links, screenshots, related issues}
```

### Issue

```markdown
# ISSUE-{NNN}: {Title}

**Status:** Open
**Severity:** {Critical | High | Medium | Low}
**Reported:** {YYYY-MM-DD}

---

## Description
{What is not working}

## Environment
- {OS, browser, version, etc.}

## Steps to Reproduce
1. {Step 1}
2. {Step 2}

## Expected vs Actual
- **Expected:** {What should happen}
- **Actual:** {What happens instead}

## Possible Cause
{If known}

## Suggested Fix
{If known}
```

### Refactor

```markdown
# Refactor: {Title}

**Status:** Proposed
**Priority:** {High | Medium | Low}
**Date:** {YYYY-MM-DD}

---

## Summary
{What is being refactored and why}

## Current State
{How the code currently works — problems, tech debt, duplication}

## Proposed Changes
- {Change 1}
- {Change 2}

## Risks
- {Risk 1 and mitigation}

## Implementation Steps
1. {Step 1}
2. {Step 2}

## Verification
{How to verify nothing broke}
```

## Workflow

When a ticket is detected:

1. **Determine ticket type** from the user's message using the detection rules above
2. **Determine the target directory** using the directory mapping
3. **Calculate the next ticket number** by listing existing files in the target directory
4. **Extract the title** from the user's message (make it concise and descriptive)
5. **Generate the slug** from the title (lowercase, hyphens, max ~50 chars)
6. **Fill in the template** with details from the user's message, using today's date for `Reported`/`Date` fields
7. **Write the file** using the `write_file` tool
8. **Confirm to the user** with the ticket path and a brief summary

### Important Rules

- Use the `write_file` tool (not shell commands) to create ticket files
- Always use absolute paths when calling `write_file`
- Use today's date (`YYYY-MM-DD`) for date fields
- Leave sections as `{placeholder}` only if the user hasn't provided enough detail — prefer filling in what you can infer
- Ask the user to confirm before creating if the ticket type is ambiguous
- If the user provides a title explicitly, use it; otherwise derive a concise title from their description
- The `Status` field should always start as `Open` (or `Proposed` for Refactors)

## Example

**User says:** "We need a feature to allow users to upload profile avatars"

**Agent detects:** Feature (keyword: "feature", "need")

**Agent creates:** `.qwen/feature/003-user-avatar-upload.md` with:

```markdown
# Feature: User Avatar Upload

## Overview
Allow users to upload and manage profile avatars.

---

## Requirements
- Users can upload an avatar image from their profile page
- Supported formats: JPG, PNG, GIF
- Max file size: 5MB
- Avatar displays in header and order history

## Implementation Notes
- Use Active Storage for image handling
- Add image validation (type, size)
- Generate thumbnails for different display contexts

## Acceptance Criteria
- [ ] Upload button appears on profile page
- [ ] Image is validated before upload
- [ ] Avatar displays correctly across the app
- [ ] Old avatar is replaced on new upload
```
