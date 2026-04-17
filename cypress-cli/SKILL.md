---
name: cypress-cli
description: Automates browser interactions for web testing, form filling, screenshots, and data extraction using cypress-cli. Use when the user needs to navigate websites, interact with web pages, fill forms, take screenshots, test web applications, extract information from web pages, mock network requests, manage browser sessions, or generate test code.
  allowed-tools: Bash(cypress-cli:*)
metadata:
  author: jovd83
  version: '1.0'
  dispatcher-category: testing
  dispatcher-capabilities: browser-automation-cli, cypress-cli-automation
  dispatcher-accepted-intents: drive_cypress_browser_cli
  dispatcher-input-artifacts: browser_task, target_url, automation_constraints
  dispatcher-output-artifacts: browser_run_artifact, cli_workflow, generated_steps
  dispatcher-stack-tags: cypress, cli, browser-automation
  dispatcher-risk: medium
  dispatcher-writes-files: true
---

## Telemetry & Logging
> [!IMPORTANT]
> All usage of this skill must be logged via the Skill Dispatcher to ensure audit logs and wallboard analytics are accurate:
> `./log-dispatch.cmd --skill <skill_name> --intent <intent> --reason <reason>` (or `./log-dispatch.sh` on Linux)

# Browser Automation with cypress-cli

> CLI-first Cypress automation for navigation, interaction, mocking, diagnostics, and test generation.

## Quick Start

```bash
# Install and set up
cypress-cli install --skills
cypress-cli install-browser

# Open a browser and navigate
cypress-cli open https://cypress.io

# Inspect interactive refs (e1, e2, e3...)
cypress-cli snapshot

# Interact
cypress-cli click e15
cypress-cli fill e5 "search query"
cypress-cli press Enter

# Capture evidence
cypress-cli screenshot --filename=home.png

# Close
cypress-cli close
```

## Golden Rules

1. Always `snapshot` before interacting; never guess refs.
2. Prefer user-level actions (`fill`, `click`, `select`) over brittle JS hacks.
3. Use named sessions (`-s=name`) for isolation and parallel role checks.
4. Save and restore state for auth-heavy flows (`state-save` / `state-load`).
5. Prefer deterministic waits (`cy.intercept` + `cy.wait('@alias')`) over fixed sleeps.
6. Use queue-safe Cypress patterns in `run-code` (no non-Cypress APIs, and do not await Cypress commands).
7. Capture screenshots/video/console/network logs for debugging evidence.
8. Avoid `force: true` unless there is no accessible user path.
9. Mock external dependencies intentionally and keep fixtures realistic.
10. Clean up sessions (`close`, `close-all`, `kill-all`) after scripts.

## Official References

- Cypress best practices: https://docs.cypress.io/guides/references/best-practices

## Capability and Limits Matrix

| Capability | Primary commands | Status | Notes and constraints |
|---|---|---|---|
| Multi-session isolation | `-s=<name>`, `list`, `close-all` | Supported | Each session keeps separate storage/cookies/tabs. |
| State reuse | `state-save`, `state-load` | Supported | Treat state files as secrets; rotate and delete when stale. |
| Network stubbing | `route`, `unroute`, `network` | Supported | Prefer stubbing external dependencies over app internals. |
| Runtime custom logic | `run-code` | Supported | Use Cypress command queue patterns; avoid `await cy...`. |
| Visual evidence capture | `screenshot`, `video-start`, `video-stop` | Supported | Video command support depends on CLI/runtime integration. |
| Tab workflows | `tab-new`, `tab-select`, `tab-close` | Partial | Browser/runtime dependent; use deterministic app-state assertions. |
| PDF export | `pdf` | Partial | Availability depends on browser + CLI integration. |
| Low-level tracing wrappers | `tracing-start`, `tracing-stop` | Optional | Only available when the CLI integration enables them. |
| Cross-browser runs | `open --browser=...` | Supported | Verify availability per environment (`chrome`, `firefox`, `msedge`, `electron`). |

## Command Reference

### Core Interaction

```bash
cypress-cli open [url]                    # Launch browser and optionally navigate
cypress-cli goto <url>                    # Navigate to URL
cypress-cli snapshot                      # Show page elements with refs
cypress-cli snapshot --filename=snap.yaml # Save snapshot to file
cypress-cli click <ref>                   # Click an element
cypress-cli dblclick <ref>                # Double-click
cypress-cli fill <ref> "value"            # Clear and fill input
cypress-cli type "text"                   # Type keystroke-by-keystroke
cypress-cli select <ref> "option-value"   # Select dropdown option
cypress-cli check <ref>                   # Check a checkbox
cypress-cli uncheck <ref>                 # Uncheck a checkbox
cypress-cli hover <ref>                   # Hover over element
cypress-cli drag <src-ref> <dst-ref>      # Drag and drop
cypress-cli upload <ref> ./file.pdf       # Upload files
cypress-cli eval "document.title"         # Evaluate JS expression
cypress-cli eval "el => el.textContent" <ref>  # Evaluate JS on element
cypress-cli close                         # Close current browser
```

### Navigation

```bash
cypress-cli go-back
cypress-cli go-forward
cypress-cli reload
```

### Keyboard and Mouse

```bash
cypress-cli press Enter
cypress-cli press ArrowDown
cypress-cli keydown Shift
cypress-cli keyup Shift
cypress-cli mousemove 150 300
cypress-cli mousedown [right]
cypress-cli mouseup [right]
cypress-cli mousewheel 0 100
```

### Dialogs and Tabs

```bash
cypress-cli dialog-accept
cypress-cli dialog-accept "text"
cypress-cli dialog-dismiss

cypress-cli tab-list
cypress-cli tab-new [url]
cypress-cli tab-select <index>
cypress-cli tab-close [index]
```

### Screenshots and Media

```bash
cypress-cli screenshot
cypress-cli screenshot <ref>
cypress-cli screenshot --filename=pg.png
cypress-cli pdf --filename=report.pdf
cypress-cli video-start
cypress-cli video-stop output.webm
cypress-cli resize 1920 1080
```

### Storage and Auth

```bash
cypress-cli state-save [file.json]
cypress-cli state-load <file.json>
cypress-cli cookie-list [--domain=...]
cypress-cli cookie-get <name>
cypress-cli cookie-set <name> <value> [opts]
cypress-cli cookie-delete <name>
cypress-cli cookie-clear
cypress-cli localstorage-list
cypress-cli localstorage-get <key>
cypress-cli localstorage-set <key> <val>
cypress-cli localstorage-delete <key>
cypress-cli localstorage-clear
cypress-cli sessionstorage-list
cypress-cli sessionstorage-get <key>
cypress-cli sessionstorage-set <key> <val>
cypress-cli sessionstorage-delete <key>
cypress-cli sessionstorage-clear
```

### Network and Debugging

```bash
cypress-cli route "<pattern>" [opts]
cypress-cli route-list
cypress-cli unroute "<pattern>"
cypress-cli unroute

cypress-cli console [level]
cypress-cli network
cypress-cli tracing-start                # Optional low-level diagnostics wrapper if enabled
cypress-cli tracing-stop                 # Optional low-level diagnostics wrapper if enabled
cypress-cli run-code "() => {}"
```

### Sessions and Configuration

```bash
cypress-cli -s=<name> <command>
cypress-cli list
cypress-cli close-all
cypress-cli kill-all
cypress-cli delete-data
cypress-cli open --browser=chrome
cypress-cli open --browser=firefox
cypress-cli open --browser=msedge
cypress-cli open --browser=electron
cypress-cli open --persistent
cypress-cli open --profile=/path
cypress-cli open --config=config.json
cypress-cli open --extension
```

## Guide Index

### Getting Started

| What you are doing | Guide |
|---|---|
| Core browser interaction | [core-commands.md](core-commands.md) |
| Generating test code | [test-generation.md](test-generation.md) |
| Screenshots, video, PDF | [screenshots-and-media.md](screenshots-and-media.md) |

### Testing and Debugging

| What you are doing | Guide |
|---|---|
| Debugging and artifacts | [debugging-and-artifacts.md](debugging-and-artifacts.md) |
| Network mocking and interception | [request-mocking.md](request-mocking.md) |
| Running custom Cypress code | [running-custom-code.md](running-custom-code.md) |

### State and Sessions

| What you are doing | Guide |
|---|---|
| Cookies, localStorage, auth state | [storage-and-auth.md](storage-and-auth.md) |
| Multi-session management | [session-management.md](session-management.md) |

### Advanced

| What you are doing | Guide |
|---|---|
| Device and environment emulation | [device-emulation.md](device-emulation.md) |
| Complex multi-step workflows | [advanced-workflows.md](advanced-workflows.md) |