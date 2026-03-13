# Changelog

All notable changes to the `cypress-skill` will be documented in this file.

## [1.0.0] - 2026-03-13

### Added
- **Cypress Handover**: Added `documentation/cypress-handover/SKILL.md` for task state preservation.
- **Session State Compatibility**: Added `documentation/session-state/SKILL.md` (thin alias for handover).
- **Coverage Auto-Sync**: Added `coverage_plan/auto-sync/SKILL.md` to keep requirements test-traceability matrices fully synchronized automatically.
- **Route Behavior**: Added `core/route-behavior.md` for handling complex navigation and redirects.
- **Locator Resilience**: Added `core/locator-resilience.md` for avoiding strict mode and scoping collisions.
- **Testability Hooks**: Added `core/testability-hooks.md` for defining automation contracts.
- **API Handler Hardening**: Added `core/api-handler-hardening.md` for mock-driven endpoint unit testing concepts.
- **Stability Diagnostics**: Added `core/stability-diagnostics.md` for resolving flaky pointer intercept and race condition issues.
- **Preflight**: Added `core/preflight.md` for readiness triage and repo health checks prior to test execution.
- **Contract First Mocking**: Added `core/contract-first-mocking.md` and strategies for temporary frontend unblocking.
- **Quality Gate Scripts**: Added Pester tests (`tests/pester/`) and specialized check scripts for handover packages, smoke tests, and CI workflows.
- **Requested Improvements**: Added `requested_improvements/` for structural parity with sister skill trees.

### Changed
- **Golden Rules** (`SKILL.md`): Added explicit strict Triad Architecture mandates. Added rules against placeholder assertions and global test namespace pollution. Added rules ensuring POMs target repetition specifically.
