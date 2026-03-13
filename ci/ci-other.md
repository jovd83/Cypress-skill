# CI: CircleCI, Azure DevOps, and Jenkins

> **When to use**: You are not on GitHub Actions or GitLab and need production-ready Cypress pipelines.
> **Prerequisites**: [docker-and-containers.md](docker-and-containers.md), [parallel-and-sharding.md](parallel-and-sharding.md), [reporting-and-artifacts.md](reporting-and-artifacts.md)

## CircleCI

```yaml
# .circleci/config.yml
version: 2.1

jobs:
  cypress-e2e:
    docker:
      - image: cypress/browsers:node-20.11.1-chrome-121-ff-122
    steps:
      - checkout
      - restore_cache:
          keys:
            - v1-npm-{{ checksum "package-lock.json" }}
      - run: npm ci
      - run: npx cypress verify
      - run: npx cypress run --browser chrome --headless
      - save_cache:
          paths:
            - node_modules
            - ~/.cache/Cypress
          key: v1-npm-{{ checksum "package-lock.json" }}
      - store_artifacts:
          path: cypress/screenshots
      - store_artifacts:
          path: cypress/videos

workflows:
  cypress:
    jobs:
      - cypress-e2e
```

Add a dedicated handover-docs job when you want machine-readable Pester results for the Cypress handover package:

```yaml
  cypress-handover-docs:
    docker:
      - image: mcr.microsoft.com/powershell:7.4-ubuntu-22.04
    steps:
      - checkout
      - run: pwsh -NoProfile -Command "if (-not (Get-Module -ListAvailable Pester)) { Install-Module Pester -Force -SkipPublisherCheck -Scope CurrentUser }"
      - run: pwsh -NoProfile -File ./scripts/check-cypress-handover-pester.ps1 -ResultsPath ./artifacts/pester/cypress-handover.xml
      - store_artifacts:
          path: artifacts/pester
```

## Azure DevOps

```yaml
# azure-pipelines.yml
trigger:
  - main
pr:
  - main

pool:
  vmImage: ubuntu-latest

steps:
  - task: NodeTool@0
    inputs:
      versionSpec: '20.x'

  - script: npm ci
    displayName: Install dependencies

  - script: npx cypress verify
    displayName: Verify Cypress

  - script: npx cypress run --browser chrome --headless
    displayName: Run Cypress
    env:
      CYPRESS_BASE_URL: $(CYPRESS_BASE_URL)
      CYPRESS_USER_EMAIL: $(CYPRESS_USER_EMAIL)
      CYPRESS_USER_PASSWORD: $(CYPRESS_USER_PASSWORD)

  - task: PublishBuildArtifacts@1
    condition: always()
    inputs:
      PathtoPublish: cypress/screenshots
      ArtifactName: cypress-screenshots

  - task: PublishBuildArtifacts@1
    condition: always()
    inputs:
      PathtoPublish: cypress/videos
      ArtifactName: cypress-videos

  - task: PowerShell@2
    displayName: Run Cypress handover Pester suite
    inputs:
      filePath: ./scripts/check-cypress-handover-pester.ps1
      arguments: -ResultsPath ./artifacts/pester/cypress-handover.xml

  - task: PublishBuildArtifacts@1
    condition: always()
    inputs:
      PathtoPublish: artifacts/pester
      ArtifactName: cypress-handover-pester
```

## Jenkins

```groovy
// Jenkinsfile
pipeline {
  agent any

  tools {
    nodejs 'node-20'
  }

  stages {
    stage('Install') {
      steps {
        sh 'npm ci'
      }
    }

    stage('Verify') {
      steps {
        sh 'npx cypress verify'
      }
    }

    stage('E2E') {
      steps {
        sh 'npx cypress run --browser chrome --headless'
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'cypress/screenshots/**', allowEmptyArchive: true
      archiveArtifacts artifacts: 'cypress/videos/**', allowEmptyArchive: true
      junit 'cypress/results/*.xml'
      archiveArtifacts artifacts: 'artifacts/pester/**', allowEmptyArchive: true
    }
  }
}
```

Add a docs stage before or after Cypress execution when you want Jenkins to publish the handover Pester XML:

```groovy
    stage('Handover Docs') {
      steps {
        powershell '.\\scripts\\check-cypress-handover-pester.ps1 -ResultsPath .\\artifacts\\pester\\cypress-handover.xml'
      }
    }
```

## Parallelization Guidance

- Prefer Cypress Cloud: `--record --parallel --group`.
- If not using Cloud, split specs at CI layer (matrix/jobs) and pass `--spec` subsets.
- Keep data isolation strict across parallel jobs.

## Anti-Patterns

| Anti-pattern | Why it hurts |
|---|---|
| Running headed browsers in CI by default | Slower and less stable under load |
| No test artifacts | Debugging failures becomes guesswork |
| Shared test accounts across jobs | Cross-job race conditions |

## Related

- [parallel-and-sharding.md](parallel-and-sharding.md)
- [docker-and-containers.md](docker-and-containers.md)
- [reporting-and-artifacts.md](reporting-and-artifacts.md)
