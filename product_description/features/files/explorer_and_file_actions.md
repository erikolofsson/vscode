# Explorer & Files — Feature overview

This document synthesizes responsibilities, public APIs, UI contributions, lifecycles, port risks, and tests for the Files/Explorer area implemented under the repository path [`src/vs/workbench/contrib/files/browser/`](src/vs/workbench/contrib/files/browser:1).

## Primary responsibilities

- Provide the Explorer view and Open Editors view UI and container registration.
- Maintain the explorer model (roots, children), react to FS events and workspace changes.
- Provide file operations (create, rename, delete, copy, move, paste, upload, download).
- Wire commands, keybindings and context keys for file interactions and editor integration.

## Key source files

- Explorer container & viewlet registration: [`src/vs/workbench/contrib/files/browser/explorerViewlet.ts:1`](src/vs/workbench/contrib/files/browser/explorerViewlet.ts:1)
- Explorer service, model coordination, refresh, select and reveal behavior: [`src/vs/workbench/contrib/files/browser/explorerService.ts:1`](src/vs/workbench/contrib/files/browser/explorerService.ts:1)
- Actions and contextual file commands exposed to menus and keybindings: [`src/vs/workbench/contrib/files/browser/fileActions.ts:1`](src/vs/workbench/contrib/files/browser/fileActions.ts:1)
- Command registration and editor integration (open, save, compare, reveal): [`src/vs/workbench/contrib/files/browser/fileCommands.ts:1`](src/vs/workbench/contrib/files/browser/fileCommands.ts:1)
- Import/export, browser upload, download and drag/drop helpers: [`src/vs/workbench/contrib/files/browser/fileImportExport.ts:1`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:1)

## Important classes & APIs

- ExplorerViewletViewsContribution / ExplorerViewPaneContainer
  - Registers view descriptors and the Explorer view container. See [`explorerViewlet.ts:45`](src/vs/workbench/contrib/files/browser/explorerViewlet.ts:45).
- ExplorerService
  - Single coordination point for the explorer model, file events, and view registration. Core methods: `registerView`, `getContext`, `select(resource, reveal)`, `applyBulkEdit(...)`, `refresh()`. See [`explorerService.ts:32`](src/vs/workbench/contrib/files/browser/explorerService.ts:32).
- BrowserFileUpload
  - Handles drag-and-drop and input-based uploads; buffered and unbuffered upload paths; parallelism limiter. See [`fileImportExport.ts:72`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:72).
- FileDownload
  - Browser vs native download paths, using File System Access API when available. See [`fileImportExport.ts:592`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:592).
- Action/Command classes in `fileActions.ts` and command registration in `fileCommands.ts`.

## UI contributions & wiring

- View container registration and icons: registered via the platform Registry and `ViewContainersRegistry` in [`explorerViewlet.ts:252`](src/vs/workbench/contrib/files/browser/explorerViewlet.ts:252).
- Welcome content for empty workspace / folder scenarios (multiple ContextKeyExpr conditions). See welcome registrations in [`explorerViewlet.ts:285`](src/vs/workbench/contrib/files/browser/explorerViewlet.ts:285).
- Open Editors view descriptor and focus commands defined in [`explorerViewlet.ts:107`](src/vs/workbench/contrib/files/browser/explorerViewlet.ts:107).
- Actions expose global commands and Action2 subclasses (e.g., `GlobalCompareResourcesAction`, `ToggleAutoSaveAction`, `FocusFilesExplorer`) in [`fileActions.ts:504`](src/vs/workbench/contrib/files/browser/fileActions.ts:504).
- Commands and keybindings for open, copy path, compare, save, revert etc. are registered in [`fileCommands.ts:81`](src/vs/workbench/contrib/files/browser/fileCommands.ts:81).

## Data model & lifecycle notes

- The ExplorerModel maintains `roots` and ExplorerItem nodes; explorerService manipulates model and coordinates view refreshes. See [`explorerService.ts:61`](src/vs/workbench/contrib/files/browser/explorerService.ts:61).
- File system events batching and delayed reaction: `onFileChangesScheduler` uses a RunOnceScheduler to debounce updates (`EXPLORER_FILE_CHANGES_REACT_DELAY`). See [`explorerService.ts:35`](src/vs/workbench/contrib/files/browser/explorerService.ts:35).
- Editable/rename lifecycle: explorerService.setEditable(...) pins editable state and suspends certain file-change reactions while editing. See [`explorerService.ts:232`](src/vs/workbench/contrib/files/browser/explorerService.ts:232).
- Bulk edits use IBulkEditService via ExplorerService.applyBulkEdit to support undo/redo semantics and progress reporting. See [`explorerService.ts:184`](src/vs/workbench/contrib/files/browser/explorerService.ts:184).

## Notable UX flows

- Create new file/folder: `openExplorerAndCreate` presents inline editable model node, validation via `validateFileName`, then bulk edit to create. See [`fileActions.ts:907`](src/vs/workbench/contrib/files/browser/fileActions.ts:907).
- Delete: `deleteFiles` handles dirty working copies, read-only checks, confirmation, Trash vs permanent delete, and uses applyBulkEdit to perform deletion with undo metadata. See [`fileActions.ts:96`](src/vs/workbench/contrib/files/browser/fileActions.ts:96).
- Paste/Copy/Move: `pasteFileHandler` distinguishes native paths vs clipboard data, computes targets via `findValidPasteFileTarget`, and applies ResourceFileEdit(s). See [`fileActions.ts:1127`](src/vs/workbench/contrib/files/browser/fileActions.ts:1127).
- Upload (browser): `BrowserFileUpload` supports parallel uploads, chunked streaming for large files, and progress aggregation. See [`fileImportExport.ts:72`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:72).
- Download (browser/native): `FileDownload` chooses FS access vs blob download based on size and platform, and remembers last-used download folder. See [`fileImportExport.ts:592`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:592).

## Context keys, menus & visibility

- Uses ContextKeyExpr extensively for welcome content, action visibility and keybinding when clauses (examples in `explorerViewlet.ts` and `fileCommands.ts`).
- Exposes RawContextKey `fileCopied` and others in [`fileActions.ts:73`](src/vs/workbench/contrib/files/browser/fileActions.ts:73).

## Integration points & dependencies

- Services: IFileService, IEditorService, IWorkspaceContextService, IClipboardService, IBulkEditService, IProgressService, IStorageService.
- Editor integration: openEditor, openEditors, save/revert flows coordinate with editor service and working copy services (`fileActions.ts`, `fileCommands.ts`).
- Filesystem capabilities: path case sensitivity, provider activation and provider-specific features are used in import/export code (`fileImportExport.ts`).

## Tests and testability

- Unit-testable pure functions present:
  - `incrementFileName(...)` in [`fileActions.ts:364`](src/vs/workbench/contrib/files/browser/fileActions.ts:364).
  - `validateFileName(...)` in [`fileActions.ts:722`](src/vs/workbench/contrib/files/browser/fileActions.ts:722).
- Suggested test areas:
  - ExplorerService reactions to FileChangesEvent batching & reveal/exclude matching.
  - Bulk edit application and undo/redo behaviour for create/rename/delete/move.
  - BrowserFileUpload buffering vs unbuffered paths with cancellation.
  - FileDownload path selection and Web FileSystem Access fallback logic.

## Porting risks & mitigations

- Dependency on IBulkEditService and ResourceFileEdit:
  - Risk: target host may not support the same bulk-edit API. Mitigation: provide an adapter that falls back to individual file operations (create/copy/delete) and surface best-effort undo or prompt the user.
- File system provider features and capabilities:
  - Risk: path case-sensitivity or provider activation semantics differ. Mitigation: centralize capability checks and provide safe defaults.
- Browser-specific APIs (File.stream, File System Access):
  - Risk: non-browser hosts or older browsers may lack streaming and FS APIs. Mitigation: keep both buffered and unbuffered code-paths with feature detection (already present).
- ContextKey/menu system:
  - Risk: host lacking ContextKeyExpr support will need a simplified visibility model. Mitigation: provide a minimal local predicate mechanism.
- Undo/Redo size limits and trash semantics:
  - Risk: MAX_UNDO_FILE_SIZE and trash APIs may not exist. Mitigation: respect size thresholds and fall back to permanent delete with explicit confirmation.

## Suggested porting checklist (minimal)

1. Implement or adapt ExplorerModel + ExplorerService equivalent (roots, findClosest, select, refresh).
2. Provide IBulkEdit-like API or adapter for multi-file atomic operations with progress & undo metadata.
3. Reimplement Browser upload/download features using host-provided streaming or file APIs; ensure cancellation.
4. Port action/command wiring (Action2/CommandsRegistry) and context-key system or provide substitutes for visibility expressions.
5. Port validation helpers and unit tests for filename logic and incremental naming.

## Related source files (read in this batch)

- [`src/vs/workbench/contrib/files/browser/explorerViewlet.ts:1`](src/vs/workbench/contrib/files/browser/explorerViewlet.ts:1)
- [`src/vs/workbench/contrib/files/browser/explorerService.ts:1`](src/vs/workbench/contrib/files/browser/explorerService.ts:1)
- [`src/vs/workbench/contrib/files/browser/fileActions.ts:1`](src/vs/workbench/contrib/files/browser/fileActions.ts:1)
- [`src/vs/workbench/contrib/files/browser/fileCommands.ts:1`](src/vs/workbench/contrib/files/browser/fileCommands.ts:1)
- [`src/vs/workbench/contrib/files/browser/fileImportExport.ts:1`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:1)

## Next steps

- Continue reading `src/vs/workbench/contrib/files/browser/views/` (ExplorerView/OpenEditorsView) and `editors/` subfolder to capture editors & tree-view specifics.
- Create per-feature docs: Explorer UI, Open Editors, Drag & Drop Uploads, Download/Export, Bulk Edit semantics.

Document prepared from reading files in this batch. End.
