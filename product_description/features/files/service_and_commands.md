# Files: Services & Commands

Summary:

This document synthesizes responsibilities and porting notes for core files service and command pieces in the Files contribution:
- [`src/vs/workbench/contrib/files/browser/explorerService.ts:1`](src/vs/workbench/contrib/files/browser/explorerService.ts:1)
- [`src/vs/workbench/contrib/files/browser/workspaceWatcher.ts:1`](src/vs/workbench/contrib/files/browser/workspaceWatcher.ts:1)
- [`src/vs/workbench/contrib/files/browser/fileActions.ts:1`](src/vs/workbench/contrib/files/browser/fileActions.ts:1)
- [`src/vs/workbench/contrib/files/browser/fileCommands.ts:1`](src/vs/workbench/contrib/files/browser/fileCommands.ts:1)
- [`src/vs/workbench/contrib/files/browser/files.ts:1`](src/vs/workbench/contrib/files/browser/files.ts:1)

Responsibilities

- ExplorerService: coordinates model <-> view lifecycle, reacts to file events, maintains editable/cut state, exposes operations such as select(), refresh(), applyBulkEdit(), setToCopy(). See [`explorerService.ts`](src/vs/workbench/contrib/files/browser/explorerService.ts:1).
- WorkspaceWatcher: manages file watching subscriptions per workspace folder, reacts to watch errors and configuration changes. See [`workspaceWatcher.ts`](src/vs/workbench/contrib/files/browser/workspaceWatcher.ts:1).
- fileActions.ts: high-level user actions for create/rename/delete/copy/paste/upload/download and related UI flows (confirmations, dirty/readonly checks, bulk edits). See [`fileActions.ts`](src/vs/workbench/contrib/files/browser/fileActions.ts:1).
- fileCommands.ts: registers low-level commands and keybindings used across explorer and editor (open-to-side, reveal, compare, save, revert, compressed-navigation). See [`fileCommands.ts`](src/vs/workbench/contrib/files/browser/fileCommands.ts:1).
- files.ts: small helper functions and the IExplorerService/IExplorerView interfaces used to resolve command targets from UI focus and selections. See [`files.ts`](src/vs/workbench/contrib/files/browser/files.ts:1).

Key behaviors and patterns

1) Debounced file-change reaction
- ExplorerService batches onDidFilesChange events into a RunOnceScheduler (delay 500ms) and uses model inspection (doesFileEventAffect) to decide whether to refresh the tree. Porting note: preserve batching to avoid UI churn; implement equivalent scheduler + model diffing.

2) Model-first view updates
- Many operations update the ExplorerModel then call view.refresh(...). Porting note: keep model/view separation; exposing refresh(recursive,item) is useful for incremental updates.

3) Bulk edits + undo metadata
- applyBulkEdit delegates to IBulkEditService with undo/redo metadata (UNDO_REDO_SOURCE), progress and cancellation. Operations (delete, copy, move, create, rename) are implemented using ResourceFileEdit. Porting note: provide a host adapter implementing bulk-edit semantics (atomic ops, undo labels, undo confirmation).

4) Dirty/working-copy integration
- deleteFiles and paste flows consult IWorkingCopyFileService/IWorkingCopyService to surface unsaved changes and prompt. Porting note: ensure host has a working-copy concept or emulate it to avoid data loss prompts.

5) File watching per workspace folder
- WorkspaceWatcher computes excludes/includes from configuration and subscribes via fileService.watch(path, { recursive, excludes }). On watch errors it prompts or logs telemetry. Porting note: file watching API differences must be adapted (e.g., in-browser polling vs native watchers).

6) Copy/Paste & native file handling
- Paste supports two modes: paths from clipboard (native file paths) and file data. Names incrementing is handled by incrementFileName and findValidPasteFileTarget. Porting note: implement clipboard adapter; for web-hosts where native paths are unavailable, fallback to data uploads.

7) Commands & keybindings
- fileCommands.ts registers many KeybindingsRegistry rules and CommandsRegistry handlers that rely on focus detection (getFocus) and listService. Porting note: replicate focus/resolution logic to ensure commands operate on intended targets.

Important code snippets (representative)

- applyBulkEdit wrapper:
  - see [`explorerService.ts:184`](src/vs/workbench/contrib/files/browser/explorerService.ts:184)

- deleteFiles using ResourceFileEdit + confirmation flows:
  - see [`fileActions.ts:96`](src/vs/workbench/contrib/files/browser/fileActions.ts:96)

- Paste handling (paths vs data and incremental naming):
  - see [`fileActions.ts:1126`](src/vs/workbench/contrib/files/browser/fileActions.ts:1126)

- WorkspaceWatcher watch/unwatch and exclude resolution:
  - see [`workspaceWatcher.ts:133`](src/vs/workbench/contrib/files/browser/workspaceWatcher.ts:133)

Porting risks & mitigations

- Missing IBulkEditService: Provide an adapter that maps ResourceFileEdit to host atomic ops. If true atomic undo is not feasible, implement best-effort ops and add clear user warnings.

- No native file watcher: implement a polling fallback or use platform-specific file watching; surface degraded behavior in telemetry and user-facing warnings similar to [`workspaceWatcher.ts:73`](src/vs/workbench/contrib/files/browser/workspaceWatcher.ts:73).

- No working-copy model: emulate dirty tracking or gate destructive operations behind save prompts; avoid silent data-loss.

- Clipboard differences in hosts: for paste operations, support both 'paths' and 'data' modes; in browser-only hosts rely on File API and stream-based upload implementations (`fileImportExport.ts`).

Recommended porting adapters

- BulkEditAdapter: apply ResourceFileEdit batches with progress, cancellation, and undo metadata.
- FileWatcherAdapter: unify native watcher, polling, and server-assisted events into fileService.watch API expected by workspace watcher.
- WorkingCopyAdapter: expose dirty checks and save/revert APIs used by fileActions.
- ClipboardAdapter: provide readResources()/readText()/writeResources() and support platform path extraction.

Test & QA checklist

- Unit tests for:
  - applyBulkEdit wrapper behavior: progress + cancellation + undo metadata.
  - findValidPasteFileTarget and incrementFileName for edge cases (unicode, long names).
- Integration tests:
  - Move/copy/delete flows with working copies present.
  - Watcher error handling (simulate ENOSPC/EUNKNOWN/ETERM).
- Manual / E2E:
  - Drag & drop upload with nested folders, large files, and overwrite scenarios.

Next steps

1) Create a dedicated doc for Drag & Drop, Uploads and External Import from [`fileImportExport.ts`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:1) (planned).
2) Read remaining top-level files: [`src/vs/workbench/contrib/files/browser/explorerFileContrib.ts:1`](src/vs/workbench/contrib/files/browser/explorerFileContrib.ts:1) and [`src/vs/workbench/contrib/files/browser/explorerViewlet.ts:1`](src/vs/workbench/contrib/files/browser/explorerViewlet.ts:1) and the editors folder if any remaining files.
3) Produce per-feature TODOs and update MANIFEST.

Owner: Kilo Code

End.
