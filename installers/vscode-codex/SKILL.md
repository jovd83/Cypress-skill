---
name: cypress-installer-vscode-codex
description: A skill to guide the installation and configuration of Cypress testing within VSCode alongside OpenAI Codex.
---

# VSCode with OpenAI Codex Installation

This skill provides the steps to set up the ideal environment for AI-assisted Cypress testing inside Visual Studio Code.

## Prerequisites
- Node.js installed.
- VSCode installed.
- Access to an OpenAI API key for Codex/GitHub Copilot.

## Installation Steps
1. **Initialize Cypress**
   Run `npm init cypress@latest` in the terminal.
   Choose TypeScript (recommended), and accept the default folders.
2. **Install AI Extensions**
   - Install the **GitHub Copilot** extension for VSCode.
   - Alternatively, install any OpenAI Codex-compatible VSCode extension.
3. **Configure Codex**
   Insert your OpenAI API key into the chosen extension's settings.
4. **Load Skills**
   Use these markdown documentation skills to guide Codex via the chat interface by referencing the `SKILL.md` guides for Cypress structure.









