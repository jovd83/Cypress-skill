---
name: cypress-mapper-xray
description: Test-management mapping skill for Xray. Use when Codex needs to apply authoritative Xray issue or case IDs back into local Cypress docs, titles, or annotations so the repository can trace automation to imported Xray records.
metadata:
  author: jovd83
  version: "1.1"
---

# Xray Mapper

Use this skill after Xray has assigned IDs and the local repository needs to reflect them.

## Action

Inputs:

- an authoritative mapping from local scenario names or paths to Xray IDs,
- the target markdown or automation files,
- the team convention for where IDs belong in docs or test titles.

Output contract:

- updated local docs or code references,
- a summary of which IDs were applied where,
- any ambiguous matches that still need human confirmation.

Guardrails:

- Do not invent IDs.
- Do not overwrite an existing different ID without calling out the conflict.
- Prefer annotations or title conventions already used by the repository.
