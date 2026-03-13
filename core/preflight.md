# Preflight Readiness

> **When to use**: Before executing a full Cypress suite or before promoting a feature story to "Ready for Implementation". Ensures the playground is clean and the actors are ready.

## Quick Reference

- **Repo Health**: `npm run build` and `npm test -- --passWithNoTests` to check for broken imports.
- **Service Recovery**: Check if stubs need replacement with real services.
- **DB Check**: Validate `process.env.DATABASE_URL` connectivity.
- **Stub Detection**: Search for `TODO: stub` or `cy.intercept` placeholders for mock responses in core flows.

## Checklist for E2E Execution

### 1. Environment Readiness
- [ ] **Dependency Check**: All packages installed (`npm install`).
- [ ] **Build Health**: Project builds without errors (`npm run build`).
- [ ] **Asset Availability**: Static assets and public folders are present.
- [ ] **Route Stability**: Core application routes are responding (`200 OK`).

### 2. Database & Data
- [ ] **Connectivity**: Database is reachable from the test environment.
- [ ] **Schema Sync**: Migration status is up to date.
- [ ] **Seed Data**: Required seed data (e.g., admin user, default settings) is present.

### 3. Service Recovery
- [ ] **Stub Identification**: Identify which external services are currently stubbed using `cy.intercept`.
- [ ] **Parity Check**: Ensure stub behavior matches current API specifications.
- [ ] **Recovery Plan**: If the test requires real integration, ensure the service is up and credentials are valid.

## Checklist for Requirement "Ready" Gate

Phase | Check | Goal
---|---|---
**Analysis** | Requirement ACs are atomic and verifiable | No ambiguous "ensure it works"
**Technical** | Route/build readiness | Avoid testing features that don't have endpoints yet
**Automation** | Locator strategy discussed | `data-testid` needs identified for complex UI
**Environment** | Stateful feature readiness | DB schema changes for this requirement are merged/available

## Implementation Patterns

The preflight check can be implemented in any language. The goal is to fail fast before the expensive Cypress suite starts.

### Reference Implementation (Example: Node.js / Prisma)

```typescript
// scripts/preflight.ts
import { execSync } from 'child_process';
import { DatabaseClient } from './db'; // Abstract your DB client

async function preflight() {
  console.log('--- PREFLIGHT READINESS CHECK ---');

  // 1. Build check
  try {
    // Replace with your build command (e.g., 'go build', 'mvn package', etc.)
    const buildCmd = process.env.BUILD_CMD || 'npm run build';
    execSync(buildCmd, { stdio: 'inherit' });
  } catch (e) {
    console.error('Build failed. Aborting.');
    process.exit(1);
  }

  // 2. DB check
  try {
    await DatabaseClient.ping();
    console.log('Database connected.');
  } catch (e) {
    console.error('Database unreachable.');
    process.exit(1);
  }

  console.log('--- PREFLIGHT PASSED ---');
}

preflight();
```

### Other Environments
- **Python**: Use `pytest` hooks or a standalone `preflight.py` checking `psycopg2` connectivity.
- **Java**: Use a dedicated Maven profile or a `Preflight` class before your E2E suite triggers.
- **Go**: Use a `preflight_test.go` with `TestMain` to verify environment variables and DB connection strings.

## Anti-Patterns

| Anti-pattern | Why it hurts | Better approach |
|---|---|---|
| Starting a full Cypress run before checking environment readiness | Expensive failures arrive too late | Fail fast with a lightweight preflight script |
| Treating stubbed dependencies as equivalent to real integrations | Gives false confidence about deployment readiness | Record which stubs remain and rerun against real services before completion |
