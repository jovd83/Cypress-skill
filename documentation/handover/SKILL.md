---
name: cypress-handover
description: A skill to perform a structured handover to a human-in-the-loop after completing Cypress tasks.
---

# Handover to Human-in-the-Loop

Create a clear handover document at task completion summarizing changes, patterns, risks, and follow-up opportunities.

## 1. Storage and Naming

- **Directory**: `<test_documentation_root>/handovers/`
  - Default root: `docs/tests/`
- **Filename format**: `YYYYMMDD_HHmm_CypressSkillHandover.md`
  - On Windows, do not use `:` in filenames.

## 2. Content Structure

The handover must include:

### What was done
Summary of completed actions.

### Skills and subskills used
List all skills used and why.

### Non-skill actions and suggestions
Actions not covered by skills, plus proposals for new skills/subskills.

### Patterns used
Architecture or implementation patterns used (for example: POM, custom commands, fixtures).

### Anti-patterns used
Any unavoidable anti-patterns and justification.

### Strengths of the changes
Main benefits.

### Weaknesses of the changes
Known risks and limitations.

### Improvements
Concrete next improvements.

### Files added/modified
Categorize by:
- Documentation
- POMs
- Test scripts
- Configurations
- Other
Include short rationale per category.

## 3. Execution

Create and store this handover document at the end of each task unless the user asks otherwise.







