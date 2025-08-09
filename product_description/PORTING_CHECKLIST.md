# Porting checklist — template

This template is used per-feature to capture all information required to plan and execute a port.

## Feature
- name:
- short description:

## Goals
- Primary goals:
- Non-goals:

## Acceptance criteria
- Functional behavior to match:
- Performance targets:
- Compatibility targets (APIs/extensions):

## Public API (extension points / commands / events)
- Commands:
- Events:
- Contribution points:

## UI & UX
- Screens / views:
- Interaction flows:
- Keyboard shortcuts & accessibility:

## Data model
- In-memory model:
- Serialization format:
- Size and retention:

## Persistence & storage
- Where data is stored (local file, workspace, user settings):
- Migration considerations:

## External protocols / integrations
- LSP/DAP/REST/other:
- Authentication/authorization:

## Processes & runtime boundaries
- Which process(es) run the feature (renderer, main, extension host, separate process):
- IPC channels and message shapes:

## Concurrency & threading
- Expected concurrency model (single-threaded, worker threads, async tasks):
- Locking and shared state:

## Theming & styling
- Color tokens used:
- CSS classes and dynamic themes:

## Internationalization
- Strings to extract:
- Pluralization/localization notes:

## Tests to run / create
- Unit tests:
- Integration tests:
- End-to-end / smoke tests:

## CI / build considerations
- Build steps required:
- Native modules and platform-specific builds:

## Dependencies
- npm and native packages:
- External services/APIs:

## Security & privacy
- Sensitive data handling:
- Permissions and sandboxing:

## Performance constraints & benchmarks
- Latency/throughput targets:
- Memory/CPU budgets:

## Observability (logs, telemetry, error reporting)
- Telemetry events:
- Log channels and levels:

## Port steps (ordered)
1. File-level mapping: read all related source files and understand control flow
2. Create interface stubs in target language
3. Implement core algorithms and data models
4. Implement UI components
5. Wire services (IPC, storage, telemetry)
6. Implement tests and run locally
7. Integrate into CI and run smoke tests

## Required reads (files, tests)
- List files here (use file paths such as [`src/vs/editor/contrib/gotoError/browser/gotoErrorWidget.ts`](src/vs/editor/contrib/gotoError/browser/gotoErrorWidget.ts:1))

## Estimated effort & risk
- effort estimate:
- risk level:
- blockers:

## Acceptance test checklist
- All unit tests for the feature pass
- Integration tests exercising the UI flows pass
- Extension compatibility tests pass (if applicable)

## Notes
-
