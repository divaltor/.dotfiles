---
name: beans-issue-tracking
description: Use when starting work, tracking tasks, or deciding where to record discovered work - clarifies when to use TodoWrite vs Beans
---

## Task Tracking Hierarchy

Two systems serve different purposes. Use the right tool for the job.

| System        | Purpose                    | Persistence  | Audience                |
| ------------- | -------------------------- | ------------ | ----------------------- |
| **TodoWrite** | Live progress visibility   | Session only | User                    |
| **Beans**     | Agent memory & audit trail | Git-tracked  | Agents, future sessions |

**Core Directive:**

- **Beans = Persistent issue tracking (like Jira)**: Git-tracked, spans sessions, provides audit trail
- **TodoWrite = Real-time progress visibility**: Session-scoped, user-facing updates only
- Track non-trivial work (3+ steps) - skip trivial fixes

## When to Use Each System

**TodoWrite** — User-facing progress indicator for the current session:

- Multi-step work (3+ steps) where the user benefits from seeing progress
- Skip for background/non-user-facing work
- Skip for trivial single-step tasks

**Beans** — Persistent agent memory:

- All non-trivial work (3+ steps)
- Work that may span sessions or context boundaries
- Discovered work during implementation
- Anything needing an audit trail
- Skip for trivial single-step tasks (typo fixes, quick lookups)

## Rule: Use Both TodoWrite and Beans Together

For user-facing, non-trivial work:

1. Create a bean first (`beans create ... -s in-progress`)
2. Create a TodoWrite list for live user visibility
3. Update both as you progress
4. TodoWrite items should mirror bean checklist items

For non-user-facing work (background agents, audit-only):

- Use Beans only
- Skip TodoWrite

## Task Lifecycle

### Before Starting Work
1. Find existing work: `beans list --ready`
2. If no matching bean exists, create one:
    ```bash
    beans create "Title" -t <type> -d "Description..." -s in-progress
    ```

### During Work
- Keep bean checklist items current: `- [ ]` → `- [x]` immediately after each step
- This creates recoverable checkpoints if context is lost
- If using TodoWrite, update TodoWrite items simultaneously with bean checklist items
- TodoWrite items should mirror bean checklist items for consistency

### After Completing Work
- If no unchecked items remain: `beans update <id> -s completed`
- Add `## Summary of Changes` section to the bean file
- For scrapped beans, add `## Reasons for Scrapping` section
- If using TodoWrite, mark all TodoWrite items as completed

## Rule: Update Bean Checklists Immediately

After completing each checklist item in a bean:

1. Edit the bean file: `- [ ]` → `- [x]`
2. This creates a recoverable checkpoint if context is lost
3. The I/O overhead is acceptable for persistence

## Discovered Work

When you discover work during implementation:
1. Create bean immediately: `beans create "Title" --tag discovered --link related:<current-bean-id> -t <type> -s todo`
2. Never ignore discovered work due to context pressure
3. For epic-level discovered work, use `-t epic`

## Git Integration

Every code commit includes its associated bean file:
```bash
git commit -m "[TYPE] Description" -- src/file.ts .beans/issue-abc123.md
```

When closing a bean, reference it in the commit message:
```
<descriptive message>

Closes beans-1234.
```

## CLI Reference

```bash
# Finding work
beans list                              # All beans
beans list --ready                      # Beans ready to start (unblocked)
beans list -t bug -s todo               # Filter by type and status

# Viewing and managing beans
beans show <id>                         # View details (accepts only single ID)
beans create "Title" -t task -d "Desc" -s todo
beans update <id> -s in-progress
beans update <id> --parent <id>         # Set parent relationship
beans update <id> --blocking <id>       # Mark as blocking

# Advanced queries
beans query '{ beans(filter: { excludeStatus: ["completed", "scrapped"] }) { id title status } }'
beans query --schema                    # View full GraphQL schema

# Archive completed beans (only when user requests)
beans archive
```

Use `beans <command> --help` for full options or `beans prime` for comprehensive training.

## Relationships

- **Parent**: Hierarchy (milestone → epic → feature → task/bug). Set with `--parent <id>`
- **Blocking**: Dependencies. Set with `--blocking <id>` to indicate this bean blocks another

## Priorities

Use `-p` when creating or `--priority` when updating:
{{range .Priorities}}
- **{{.Name}}**{{if .Description}}: {{.Description}}{{end}}
{{- end}}

Beans without priority are treated as `normal` for sorting.

## Issue Types

Always specify a type with `-t` when creating beans:
{{range .Types}}
- **{{.Name}}**{{if .Description}}: {{.Description}}{{end}}
{{- end}}

## Statuses

Project-configured statuses:
{{range .Statuses}}
- **{{.Name}}**{{if .Description}}: {{.Description}}{{end}}
{{- end}}
