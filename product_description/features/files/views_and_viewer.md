# Explorer Views & Viewer — Feature detail

This document synthesizes responsibilities, lifecycles, and port risks for the Explorer view, Open Editors view, and the viewer components under [`src/vs/workbench/contrib/files/browser/views/`](src/vs/workbench/contrib/files/browser/views:1).

Primary responsibilities

- Render workspace roots, folders and files in a compressible tree.
- Provide inline rename / create input box and validation.
- Support filtering, searching (find provider), and highlighting of results.
- Supply decorations for roots and file statuses.
- Handle drag & drop (native, external, intra-explorer) including upload/import logic hooks.
- Expose context menus, view title actions and accessibility semantics.

Key source files

- [`src/vs/workbench/contrib/files/browser/views/explorerView.ts:1`](src/vs/workbench/contrib/files/browser/views/explorerView.ts:1)
- [`src/vs/workbench/contrib/files/browser/views/explorerViewer.ts:1`](src/vs/workbench/contrib/files/browser/views/explorerViewer.ts:1)
- [`src/vs/workbench/contrib/files/browser/views/openEditorsView.ts:1`](src/vs/workbench/contrib/files/browser/views/openEditorsView.ts:1)
- [`src/vs/workbench/contrib/files/browser/views/explorerDecorationsProvider.ts:1`](src/vs/workbench/contrib/files/browser/views/explorerDecorationsProvider.ts:1)
- [`src/vs/workbench/contrib/files/browser/views/emptyView.ts:1`](src/vs/workbench/contrib/files/browser/views/emptyView.ts:1)

Important classes & components

- ExplorerView (ViewPane) — creates and coordinates the WorkbenchCompressibleAsyncDataTree, manages context keys, select/autoReveal and editable lifecycle. See [`explorerView.ts:153`](src/vs/workbench/contrib/files/browser/views/explorerView.ts:153).
- ExplorerDataSource / ExplorerDelegate — provide the data-source and sizing logic for the tree. See [`explorerViewer.ts:92`](src/vs/workbench/contrib/files/browser/views/explorerViewer.ts:92).
- FilesRenderer — renders individual file/folder rows, compressed folder labels, input box and decorations. See [`explorerViewer.ts:845`](src/vs/workbench/contrib/files/browser/views/explorerViewer.ts:845).
- ExplorerFindProvider / ExplorerFindHighlightTree — supports both filter and highlight modes for explorer search. See [`explorerViewer.ts:288`](src/vs/workbench/contrib/files/browser/views/explorerViewer.ts:288).
- FilesFilter — integrates files.exclude and .gitignore semantics and ensures opened editors remain visible. See [`explorerViewer.ts:1244`](src/vs/workbench/contrib/files/browser/views/explorerViewer.ts:1244).
- FileDragAndDrop / BrowserFileUpload / ExternalFileImport — drag & drop and upload/import handling. See [`explorerViewer.ts:1585`](src/vs/workbench/contrib/files/browser/views/explorerViewer.ts:1585) and [`src/vs/workbench/contrib/files/browser/fileImportExport.ts:72`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:72).
- OpenEditorsView and related renderers — list of open editors with group support, actions and drag-and-drop. See [`openEditorsView.ts:62`](src/vs/workbench/contrib/files/browser/views/openEditorsView.ts:62).
- ExplorerDecorationsProvider — maps file-state (error, symbolic link, excluded) to decoration data. See [`explorerDecorationsProvider.ts:47`](src/vs/workbench/contrib/files/browser/views/explorerDecorationsProvider.ts:47).
- EmptyView — welcome/drag-drop behavior when no folder is open. See [`emptyView.ts:26`](src/vs/workbench/contrib/files/browser/views/emptyView.ts:26).

UI & interaction patterns

- Compressible tree: uses WorkbenchCompressibleAsyncDataTree with a compression delegate to collapse chains of single-child folders into "compressed" labels. Navigation controllers (CompressedNavigationController) let users cycle through parts of a compressed label.
- Inline editing: uses InputBox tied to ResourceLabels for create/rename flows, with validation via IEditableData and filesystem/OS name checks.
- Find modes: filter-mode creates phantom items and resets tree state, highlight-mode keeps tree input and marks matching items + badges.
- Drag & drop: three modes — native external files (import or upload), external workspace folders (add/copy), and intra-explorer moves/copies with conflict handling and optional confirm setting.
- Persistent view state: tree view state stored in storage service key and restored on setTreeInput().

Data & lifecycle notes

- setTreeInput() boots the tree and uses explorerService.roots; it records/ restores view state and registers the ExplorerDecorationsProvider after initial resolve.
- selectResource(...) expands parent chain and sets focus/selection, with guarded retry logic to handle asynchrony when nodes are not yet resolved.
- Editable state is coordinated via ExplorerService to prevent concurrent tree mutation while editing.
- FilesFilter keeps ignore trees per root and updates on file changes; opened editors are always shown even if excluded.

Accessibility & theming

- Labels include aria attributes and levels; compressed navigation updates aria-expanded and active descendant ids.
- createFileIconThemableTreeContainerScope toggles classes based on the active file icon theme to preserve alignment.
- Renderer implements IListAccessibilityProvider to provide aria labels and aria levels.

Tests & unitable components

- FilesFilter logic (isIgnored, processIgnoreFile) — unit tests can feed virtual workspace and ignore files.
- CompressedNavigationController — deterministic index changes, label updates and disposal.
- ExplorerFindProvider — filter vs highlight flows, phantom item creation and clearing.
- renderInputBox validation and focus/blur behavior — use DOM-testing harness to simulate input events.

Porting risks & mitigations

- Heavy platform dependencies: list service, ResourceLabels, storage, theme, search service, file service and editor integrations.
  - Mitigation: implement small adapter layers that provide the required subset (tree view API, label rendering, simple search) and fall back to simpler behavior if unavailable.
- Compressed folders & label alignment: relies on CSS and icon/theme interplay that may differ on target platforms.
  - Mitigation: expose a config flag to disable compression and provide fallback single-line labels.
- .gitignore handling and ignore-tree processing can be expensive and asynchronous.
  - Mitigation: keep the current design of asynchronous processing, but provide a simplified synchronous path for hosts without search/file-service.
- Drag & drop complexity across platforms (native file paths, DataTransfer APIs, File.stream).
  - Mitigation: separate platform-specific implementations (Web vs Native) and feature-detect capabilities (File.stream, File System Access).

Recommendations & next steps

1. Capture and port the core tree and renderer APIs (WorkbenchCompressibleAsyncDataTree or equivalent), ResourceLabels, and a minimal FilesFilter implementation.
2. Provide adapters for searchService and FileService so ExplorerFindProvider can be reused or a simplified fallback used.
3. Port drag & drop incrementally: start with intra-explorer moves/copies and later add native/external import and browser uploads.
4. Add focused unit tests for FilesFilter, CompressedNavigationController and ExplorerFindProvider behavior.

Files read in this batch

- [`src/vs/workbench/contrib/files/browser/views/emptyView.ts:1`](src/vs/workbench/contrib/files/browser/views/emptyView.ts:1)
- [`src/vs/workbench/contrib/files/browser/views/explorerDecorationsProvider.ts:1`](src/vs/workbench/contrib/files/browser/views/explorerDecorationsProvider.ts:1)
- [`src/vs/workbench/contrib/files/browser/views/explorerView.ts:1`](src/vs/workbench/contrib/files/browser/views/explorerView.ts:1)
- [`src/vs/workbench/contrib/files/browser/views/explorerViewer.ts:1`](src/vs/workbench/contrib/files/browser/views/explorerViewer.ts:1)
- [`src/vs/workbench/contrib/files/browser/views/openEditorsView.ts:1`](src/vs/workbench/contrib/files/browser/views/openEditorsView.ts:1)

Next actions

- Continue into [`src/vs/workbench/contrib/files/browser/editors/`](src/vs/workbench/contrib/files/browser/editors:1) to capture editor inputs and editor-specific contributions.
- Add per-feature docs: Open Editors view, Drag & Drop & Uploads, Find/Filter provider deep-dive.

End of document.
