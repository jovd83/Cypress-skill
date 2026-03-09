# Session Management

> **When to use**: Running multiple isolated browser sessions concurrently, managing persistent profiles, comparing different browser states side by side, parallel scraping, or A/B testing flows.
> **Prerequisites**: [core-commands.md](core-commands.md) for basic CLI usage

## Quick Reference

```bash
# Named sessions: each has independent cookies, storage, tabs
cypress-cli -s=auth open https://app.example.com/login
cypress-cli -s=public open https://example.com

# Interact within a session
cypress-cli -s=auth fill e1 "user@example.com"
cypress-cli -s=public snapshot

# List all active sessions
cypress-cli list

# Clean up
cypress-cli -s=auth close
cypress-cli close-all             # Close everything
cypress-cli kill-all              # Force kill zombie processes
```

## Named Sessions

Use the `-s=<name>` flag to create isolated browser instances. Each named session has its own:

- Cookies
- localStorage / sessionStorage
- IndexedDB
- Cache
- Browsing history
- Open tabs

### Creating Sessions

```bash
# Create a session for authentication testing
cypress-cli -s=admin open https://app.example.com/login

# Create a separate session for a different user
cypress-cli -s=viewer open https://app.example.com/login

# All commands in a session are isolated
cypress-cli -s=admin fill e1 "admin@company.com"
cypress-cli -s=admin fill e2 "admin-password"
cypress-cli -s=admin click e3

cypress-cli -s=viewer fill e1 "viewer@company.com"
cypress-cli -s=viewer fill e2 "viewer-password"
cypress-cli -s=viewer click e3
```

### Default Session

When `-s` is omitted, all commands share a single default session:

```bash
# These all use the same default session
cypress-cli open https://example.com
cypress-cli snapshot
cypress-cli click e1
cypress-cli close
```

## Session Isolation

Sessions are fully independent -- actions in one session never affect another:

```bash
# Session A logs in as admin
cypress-cli -s=admin open https://app.example.com
cypress-cli -s=admin fill e1 "admin@example.com"
cypress-cli -s=admin fill e2 "admin-pass"
cypress-cli -s=admin click e3

# Session B visits the same site -- NOT logged in
cypress-cli -s=guest open https://app.example.com
cypress-cli -s=guest snapshot
# Shows the login page, not the admin dashboard

# Session C can use a completely different browser
cypress-cli -s=firefox-test open https://app.example.com --browser=firefox
```

## Session Commands

```bash
# List all active sessions with their status
cypress-cli list

# Close a specific named session
cypress-cli -s=mysession close

# Close the default session
cypress-cli close

# Close ALL sessions at once
cypress-cli close-all

# Force kill all browser daemon processes (for stuck/zombie browsers)
cypress-cli kill-all

# Delete persistent profile data for a session
cypress-cli -s=mysession delete-data

# Delete default session data
cypress-cli delete-data
```

## Persistent Profiles

By default, sessions run **in-memory** -- all cookies, storage, and browsing data are lost when the session closes. Use `--persistent` to save state to disk.

### Auto-Generated Profile

```bash
# cypress-cli manages the profile directory automatically
cypress-cli -s=myapp open https://example.com --persistent

# Close and reopen -- cookies and storage are preserved
cypress-cli -s=myapp close
cypress-cli -s=myapp open https://example.com --persistent
# Still logged in!
```

### Custom Profile Directory

```bash
# Specify exactly where to store profile data
cypress-cli -s=myapp open https://example.com --profile=/tmp/my-browser-profile

# Useful for sharing profiles between sessions
cypress-cli -s=session-a open https://example.com --profile=/shared/profile
cypress-cli -s=session-a close
cypress-cli -s=session-b open https://example.com --profile=/shared/profile
```

### Cleaning Up Persistent Data

```bash
# Remove stored profile data (must close the session first)
cypress-cli -s=myapp close
cypress-cli -s=myapp delete-data
```

## Session Configuration

Configure browser engine and options per session:

```bash
# Different browsers for different sessions
cypress-cli -s=chrome-test open https://example.com --browser=chrome
cypress-cli -s=firefox-test open https://example.com --browser=firefox
cypress-cli -s=electron-test open https://example.com --browser=electron
cypress-cli -s=edge-test open https://example.com --browser=msedge

# With config file
cypress-cli -s=configured open https://example.com --config=my-config.json

# Headed mode (visible browser window)
cypress-cli -s=visible open https://example.com --headed

# Connect to existing browser via extension
cypress-cli -s=extension open --extension
```

## Environment Variable

Set a default session name so all commands use it without the `-s` flag:

```bash
export CYPRESS_CLI_SESSION="mysession"

# These now use "mysession" automatically
cypress-cli open https://example.com
cypress-cli snapshot
cypress-cli close
```

```powershell
$env:CYPRESS_CLI_SESSION = "mysession"

# These now use "mysession" automatically
cypress-cli open https://example.com
cypress-cli snapshot
cypress-cli close
```

## Common Patterns

### Multi-User Role Testing

Test the same application as different user roles simultaneously:

```bash
# Admin session
cypress-cli -s=admin open https://app.example.com/login
cypress-cli -s=admin snapshot
cypress-cli -s=admin fill e1 "admin@company.com"
cypress-cli -s=admin fill e2 "admin-pass"
cypress-cli -s=admin click e3

# Regular user session
cypress-cli -s=user open https://app.example.com/login
cypress-cli -s=user fill e1 "user@company.com"
cypress-cli -s=user fill e2 "user-pass"
cypress-cli -s=user click e3

# Compare what each role sees
cypress-cli -s=admin snapshot     # Should show admin panel
cypress-cli -s=user snapshot      # Should NOT show admin panel

cypress-cli -s=admin screenshot --filename=admin-view.png
cypress-cli -s=user screenshot --filename=user-view.png
```

### Concurrent Scraping

Scrape multiple sites in parallel for speed:

```bash
#!/bin/bash

# Launch all browsers concurrently
cypress-cli -s=site1 open https://site1.example.com &
cypress-cli -s=site2 open https://site2.example.com &
cypress-cli -s=site3 open https://site3.example.com &
wait

# Collect data from each
cypress-cli -s=site1 snapshot --filename=site1.yaml
cypress-cli -s=site2 snapshot --filename=site2.yaml
cypress-cli -s=site3 snapshot --filename=site3.yaml

# Take screenshots
cypress-cli -s=site1 screenshot --filename=site1.png
cypress-cli -s=site2 screenshot --filename=site2.png
cypress-cli -s=site3 screenshot --filename=site3.png

# Clean up
cypress-cli close-all
```

```powershell
# Launch all browsers concurrently
$jobs = @(
  Start-Job { cypress-cli -s=site1 open https://site1.example.com },
  Start-Job { cypress-cli -s=site2 open https://site2.example.com },
  Start-Job { cypress-cli -s=site3 open https://site3.example.com }
)
$jobs | Wait-Job | Out-Null
$jobs | Remove-Job

# Collect data from each
cypress-cli -s=site1 snapshot --filename=site1.yaml
cypress-cli -s=site2 snapshot --filename=site2.yaml
cypress-cli -s=site3 snapshot --filename=site3.yaml

# Take screenshots
cypress-cli -s=site1 screenshot --filename=site1.png
cypress-cli -s=site2 screenshot --filename=site2.png
cypress-cli -s=site3 screenshot --filename=site3.png

# Clean up
cypress-cli close-all
```

### A/B Testing Comparison

```bash
# Variant A
cypress-cli -s=variant-a open "https://app.example.com?variant=a"
cypress-cli -s=variant-a screenshot --filename=variant-a.png

# Variant B
cypress-cli -s=variant-b open "https://app.example.com?variant=b"
cypress-cli -s=variant-b screenshot --filename=variant-b.png

# Compare side by side
cypress-cli close-all
```

### Cross-Browser Testing

Run the same flow in multiple browsers to verify compatibility:

```bash
#!/bin/bash

for browser in chrome firefox electron; do
  cypress-cli -s=$browser open https://example.com --browser=$browser
  cypress-cli -s=$browser snapshot
  cypress-cli -s=$browser screenshot --filename="$browser-home.png"

  cypress-cli -s=$browser goto https://example.com/features
  cypress-cli -s=$browser screenshot --filename="$browser-features.png"
done

cypress-cli close-all
```

```powershell
foreach ($browser in @("chrome", "firefox", "electron")) {
  cypress-cli -s=$browser open https://example.com --browser=$browser
  cypress-cli -s=$browser snapshot
  cypress-cli -s=$browser screenshot --filename="$browser-home.png"

  cypress-cli -s=$browser goto https://example.com/features
  cypress-cli -s=$browser screenshot --filename="$browser-features.png"
}

cypress-cli close-all
```

### Authenticated State Sharing Across Sessions

```bash
# Log in once and save state
cypress-cli -s=login open https://app.example.com/login
cypress-cli -s=login fill e1 "user@example.com"
cypress-cli -s=login fill e2 "password123"
cypress-cli -s=login click e3
cypress-cli -s=login state-save auth.json
cypress-cli -s=login close

# Reuse auth state in multiple sessions
cypress-cli -s=session-a open https://app.example.com
cypress-cli -s=session-a state-load auth.json
cypress-cli -s=session-a goto https://app.example.com/dashboard

cypress-cli -s=session-b open https://app.example.com
cypress-cli -s=session-b state-load auth.json
cypress-cli -s=session-b goto https://app.example.com/settings
```

## Anti-Patterns

| Anti-pattern | Problem | Better pattern |
|---|---|---|
| Generic session names (`s1`, `test`) | Hard to reason/debug multi-session flows | Use semantic names (`admin`, `reviewer`, `scraper`) |
| Reusing one persistent profile for parallel runs | State bleed and race conditions | Isolate profiles per workflow/job |
| Leaving sessions open after scripts | Resource leaks and stale browser state | Close individual sessions or run `close-all` |
| Assuming `--persistent` is always needed | Unnecessary disk/state complexity | Keep short-lived tasks in default in-memory sessions |

## Best Practices

### 1. Name Sessions Semantically

```bash
# Good: Clear purpose
cypress-cli -s=github-auth open https://github.com
cypress-cli -s=docs-scrape open https://docs.example.com
cypress-cli -s=checkout-flow open https://shop.example.com

# Avoid: Generic names
cypress-cli -s=s1 open https://github.com
cypress-cli -s=test open https://docs.example.com
```

### 2. Always Clean Up

```bash
# Close individual sessions when done
cypress-cli -s=auth close
cypress-cli -s=scrape close

# Or close all at once
cypress-cli close-all

# If browsers become unresponsive
cypress-cli kill-all
```

### 3. Delete Stale Persistent Data

```bash
# Remove old persistent profiles to free disk space
cypress-cli -s=old-session delete-data
```

### 4. Use Default Session for Single-Task Work

Don't create named sessions when you only need one browser:

```bash
# Simple single-session workflow -- no -s flag needed
cypress-cli open https://example.com
cypress-cli snapshot
cypress-cli click e1
cypress-cli close
```

### 5. Combine with State Management

For long-running tasks, save state periodically:

```bash
cypress-cli -s=long-task open https://app.example.com --persistent
# ... many interactions ...
cypress-cli -s=long-task state-save checkpoint.json
# ... more interactions ...
# If something goes wrong, restore:
cypress-cli -s=long-task state-load checkpoint.json
```











