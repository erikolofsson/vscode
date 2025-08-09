# Overview — Code - OSS

This document is a concise, high-level description of the product, its major subsystems, and important rewrite considerations. It is intended to be the first-stop reference when planning a complete port of this repository to another language or platform.

Repository snapshot
- Product manifest: [`product_description/MANIFEST.md`](product_description/MANIFEST.md:1)
- Key repository areas to port:
  - Core runtime and UI: [`src/`](src/:1)
  - Bundled extensions: [`extensions/`](extensions/:1)
  - CLI and tools: [`cli/`](cli/:1)
  - Build and developer scripts: [`scripts/`](scripts/:1)
  - Tests and CI: [`test/`](test/:1)
  - Product metadata: [`product.json`](product.json:1), [`package.json`](package.json:1)
  - Top-level docs: [`README.md`](README.md:1), [`CONTRIBUTING.md`](CONTRIBUTING.md:1)

High-level product summary
- Visual Studio Code - Open Source (Code - OSS) is a cross-platform, extensible code editor that combines a code editor with lightweight debugging, extensibility, and integrations for language features and source control.
- Main concerns to port:
  - Editor component (text model, rendering, tokens, selections, cursors)
  - Workbench (views, panels, window management, layout)
  - Extension system and extension host (API surface, activation, messaging)
  - Language features (language server protocols, providers)
  - Debugging and runtimes (adapters, breakpoints, call stacks, variable views)
  - Filesystem and remote/workspace support (local, remote, providers)
  - Build/test tooling, packaging, and release scripts

Primary runtime & architecture boundaries
- Renderer / UI layer (browser/electron renderer): heavy DOM-based UI, list/tree components, native-like menus, and theming.
- Main/electron process (when packaged): native integrations, native menus, child processes for extension host or debug adapters.
- Extension Host: runs extensions in separate process (or worker); provides the extension API surface.
- Language / Debug Adapters: adapter processes or servers communicating via established protocols (LSP/DAP).
- Shared platform services: telemetry, storage, configuration, workspace/file services, theme service, commands, actions, menus, context keys.

Important files and directories (start-points for analysis)
- [`src/`](src/:1) — primary TypeScript source to produce renderer/main bundles and extension host code.
- [`extensions/`](extensions/:1) — built-in small extensions and language plugins; these indicate extension API usage patterns.
- [`cli/`](cli/:1) — command-line interface code (packaging/runtime helpers).
- [`scripts/`](scripts/:1) — helper scripts for running local web builds, performance, packaging, and developer tooling.
- [`test/`](test/:1) — smoke tests, browser tests, and node tests mapping to features.

Rewrite considerations & constraints
- Language/runtime mapping: The product uses heavy TypeScript/JavaScript + browser DOM. When porting to another language choose a runtime that covers:
  - Rich UI (if reusing browser — keep the DOM-based renderer)
  - Concurrency/process model (for extension host separation)
  - Inter-process communication (IPC) and protocol implementations (LSP/DAP)
- Preserve API surfaces used by extensions. The extension model is a critical compatibility surface; document and preserve activation events, commands, contribution points.
- Componentization: split the product into explicit subsystems (editor core, workbench, extension host, services) with clear interfaces to ease porting.
- Theming and styling: the product relies on theme color registrations and CSS. Capture theme registration points and color tokens in documentation for porting.
- Tests and automation: keep test mapping and CI configuration to validate behavior parity during/after port.

Immediate next steps (automated)
1. Create a porting checklist template (`product_description/PORTING_CHECKLIST.md`) to be used per-feature.
2. Create theme taxonomy files under [`product_description/themes/`](product_description/themes/:1).
3. Iteratively scan the repository (5 files at a time), extract features, and author per-feature docs under [`product_description/features/`](product_description/features/:1). Example seeds:
   - Editor / Marker navigation: found in [`src/vs/editor/contrib/gotoError/browser/gotoErrorWidget.ts`](src/vs/editor/contrib/gotoError/browser/gotoErrorWidget.ts:1) — will be documented under [`product_description/features/editor/marker_navigation.md`](product_description/features/editor/marker_navigation.md:1)
   - Workbench / Open Editors view: found in [`src/vs/workbench/contrib/files/browser/views/openEditorsView.ts`](src/vs/workbench/contrib/files/browser/views/openEditorsView.ts:1) — will be documented under [`product_description/features/workbench/open_editors.md`](product_description/features/workbench/open_editors.md:1)

How to use this docset
- Use the manifest [`product_description/MANIFEST.md`](product_description/MANIFEST.md:1) as the single source of truth.
- For each feature doc, expect:
  - Responsibilities and scope
  - Source file references (with exact file paths)
  - UI flows and interactions
  - APIs and extension points
  - Tests and CI references
  - A per-feature porting checklist and effort estimate

I will proceed automatically (per earlier instruction) and:
- create the porting checklist template next,
- then continue the iterative scan (5-file reads), populate feature docs under [`product_description/features/`](product_description/features/:1), and perform a QA pass to add exact source-file cross-links for each feature doc.
- Chat subsystem documentation has been expanded; see [`product_description/features/chat/`](product_description/features/chat:1) for the first-pass collection of feature docs (QA in progress).
I will update the manifest and affected feature docs as I make progress.
