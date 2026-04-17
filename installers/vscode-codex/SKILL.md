---
name: cypress-installer-vscode-codex
description: Editor-setup skill for Cypress plus OpenAI Codex in Visual Studio Code. Use when Codex needs to help configure a practical VS Code environment for Cypress authoring, execution, debugging, and local skill usage.
metadata:
  author: jovd83
  version: '1.1'
  dispatcher-category: testing
  dispatcher-capabilities: editor-setup, cypress-editor-setup
  dispatcher-accepted-intents: setup_cypress_editor
  dispatcher-input-artifacts: editor_choice, repo_context, local_environment
  dispatcher-output-artifacts: editor_setup_steps, configuration_guidance
  dispatcher-stack-tags: cypress, setup, editor
  dispatcher-risk: low
  dispatcher-writes-files: false
---

## Telemetry & Logging
> [!IMPORTANT]
> All usage of this skill must be logged via the Skill Dispatcher to ensure audit logs and wallboard analytics are accurate:
> `./log-dispatch.cmd --skill <skill_name> --intent <intent> --reason <reason>` (or `./log-dispatch.sh` on Linux)

# VSCode with OpenAI Codex Installation

Use this skill when the user wants a working Cypress workflow in Visual Studio Code with Codex-style assistance.

## Prerequisites

- Node.js installed
- npm or another supported package manager available
- Visual Studio Code installed
- access to the Codex or agent workflow the user actually plans to use

## Installation Steps

1. Initialize or inspect the Cypress project with `npm init cypress@latest` when Cypress is not already set up.
2. Confirm the project can install dependencies and run Cypress locally.
3. Configure the editor extensions, terminal workflow, and agent setup the user actually has available.
4. Verify local execution and debugging work in VS Code.
5. Point the user to the relevant skills in this repository for test authoring, CI, planning, or documentation.

Output contract:

- prerequisites
- setup steps
- verification commands
- editor-specific caveats
- the next recommended skill or guide after setup