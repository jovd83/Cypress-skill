---
name: cypress-installer-intellij-junie
description: Editor-setup skill for Cypress plus Junie in IntelliJ IDEA. Use when Codex needs to help configure a practical JetBrains environment for Cypress authoring, execution, debugging, and local skill usage.
metadata:
  author: jovd83
  version: "1.1"
---

# IntelliJ IDEA with Junie Installation

Use this skill when the user wants a working Cypress workflow in IntelliJ IDEA with Junie-style assistance.

## Prerequisites

- Node.js installed
- npm or another supported package manager available
- IntelliJ IDEA or a compatible JetBrains IDE installed
- access to the Junie or agent workflow the user actually plans to use

## Installation Steps

1. Initialize or inspect the Cypress project with `npm init cypress@latest` when Cypress is not already set up.
2. Confirm the project can install dependencies and run Cypress locally.
3. Configure the JetBrains plugins, terminal workflow, and agent setup the user actually has available.
4. Verify local execution and debugging work in the IDE.
5. Point the user to the relevant skills in this repository for test authoring, CI, planning, or documentation.

Output contract:

- prerequisites
- setup steps
- verification commands
- IDE-specific caveats
- the next recommended skill or guide after setup
