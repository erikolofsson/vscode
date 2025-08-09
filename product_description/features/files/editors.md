# File Editors — Feature detail

This document synthesizes responsibilities, lifecycles, APIs and porting notes for the file editor inputs and editors under [`src/vs/workbench/contrib/files/browser/editors/`](src/vs/workbench/contrib/files/browser/editors:1).

Scope
- Behavior, lifecycle and integration of file-backed editor inputs and editors:
  - Text file editor (save, save as, encoding, backup/hot-exit, revert)
  - Editor input implementation for files
  - Editor tracking (dirty, auto-save, backups)
  - Save error handling and user prompts
- Relevant files read in this batch:
  - [`src/vs/workbench/contrib/files/browser/editors/fileEditorInput.ts:1`](src/vs/workbench/contrib/files/browser/editors/fileEditorInput.ts:1)
  - [`src/vs/workbench/contrib/files/browser/editors/textFileEditor.ts:1`](src/vs/workbench/contrib/files/browser/editors/textFileEditor.ts:1)
  - [`src/vs/workbench/contrib/files/browser/editors/textFileEditorTracker.ts:1`](src/vs/workbench/contrib/files/browser/editors/textFileEditorTracker.ts:1)
  - [`src/vs/workbench/contrib/files/browser/editors/textFileSaveErrorHandler.ts:1`](src/vs/workbench/contrib/files/browser/editors/textFileSaveErrorHandler.ts:1)
  - [`src/vs/workbench/contrib/files/browser/editors/fileEditorHandler.ts:1`](src/vs/workbench/contrib/files/browser/editors/fileEditorHandler.ts:1)

Primary responsibilities (summary)
- Provide EditorInput that wraps a file resource and its metadata (encoding, mode, options), implements resolve(), matches(), backup/restore hooks, and supplies editor-capable models to the editor service.
  - See [`fileEditorInput.ts:1`](src/vs/workbench/contrib/files/browser/editors/fileEditorInput.ts:1).
- Implement TextFileEditor that connects the EditorInput to the code/text editor widget, wires save/revert/undo, and reacts to working copy events (dirty, save status, save participants).
  - See [`textFileEditor.ts:1`](src/vs/workbench/contrib/files/browser/editors/textFileEditor.ts:1).
- Track open text editors and coordinate hot-exit/backup behavior so unsaved changes are preserved across window reloads and exits.
  - See [`textFileEditorTracker.ts:1`](src/vs/workbench/contrib/files/browser/editors/textFileEditorTracker.ts:1).
- Centralize save error mapping to UX flows: retry/save-as/revert choices and telemetry logging.
  - See [`textFileSaveErrorHandler.ts:1`](src/vs/workbench/contrib/files/browser/editors/textFileSaveErrorHandler.ts:1).
- Wire-up / registration of file editor types and contribution points with the editor registry and opener service.
  - See [`fileEditorHandler.ts:1`](src/vs/workbench/contrib/files/browser/editors/fileEditorHandler.ts:1).

Key design patterns & platform contracts
- Working copy / model abstraction:
  - Editors rely on a "working copy" service (IWorkingCopyService / ITextFileService) to represent in-memory content, dirty state, save participants and backups.
  - EditorInputs take responsibility for producing or resolving models used by the editor widget and for translating save/backup requests into file service operations.
- Backup & Hot-Exit:
  - Editor tracker registers open editors and ensures dirty editors have backups persisted (via therecommended backup service) on hot-exit. On restore, backups are reconciled with on-disk contents and user prompts are surfaced when necessary.
- Save flow & participants:
  - Save includes synchronous / async participants (formatters, pre-save hooks). The editor coordinates these via working copy save lifecycle and provides progress/UI feedback.
- Encoding & Save-as:
  - FileEditorInput tracks encoding and delegates convert/save-as requests to the file service and working copy services; user-and-UI-level prompts are used when necessary.
- Error handling:
  - Save errors are mapped to common categories (conflict, permission, out-of-space) and surfaced via a centralized handler which offers contextual actions (Retry, Save As, Revert, Show Error Detail).

Lifecycle highlights
- Open:
  - EditorService requests opening a resource -> file editor handler creates/returns a `FileEditorInput` -> input.resolve() will ensure a working-copy/text model exists -> TextFileEditor attaches editor widget and subscribes to model/working copy events.
- Edit:
  - User edits -> working copy becomes dirty -> tracker ensures backup scheduling and hot-exit eligibility.
- Save:
  - Save triggers save participants -> working copy.save() -> fileService.writeFile/backup store -> on success clear dirty and possibly open saved file. Progress shown in UI; undo/redo preserved by working copy mechanics.
- Save Error:
  - Save fails -> Error handler maps error -> user is presented with Retry/SaveAs/Revert flow -> handler may trigger telemetry and fallback operations.
- Close:
  - On close, if dirty and hot-exit disabled, prompt to save/backup/revert; if hot-exit enabled, backup persists in background.

Public APIs and extension points (used by other subsystems)
- EditorInput APIs: resolve(), matches(), getName(), getResource() — consumed by editor service and other UI components.
  - See [`fileEditorInput.ts:1`](src/vs/workbench/contrib/files/browser/editors/fileEditorInput.ts:1).
- Working copy events: onDidChangeDirty, onDidSave, onDidChangeContent — consumed by tracker and UI elements to update counts and badges.
  - See [`textFileEditorTracker.ts:1`](src/vs/workbench/contrib/files/browser/editors/textFileEditorTracker.ts:1).
- Save error handler exposes UX actions and a small mapping layer; other components can call into it to present consistent prompts.
  - See [`textFileSaveErrorHandler.ts:1`](src/vs/workbench/contrib/files/browser/editors/textFileSaveErrorHandler.ts:1).

Porting risks & mitigations
- Heavy coupling with Working Copy / Backup services:
  - Risk: Host environment must provide working copy lifecycle and a backup persistence mechanism to preserve unsaved changes across restarts.
  - Mitigation: Provide a lightweight stub of a working-copy service that supports minimal dirty/save/backup semantics and persists backups to a host-supported storage (local filesystem, indexed DB, or remote store).
- Save participants and extensions:
  - Risk: Save participants (formatters, linters) may run inside extension host; ports without extension host need either to emulate or disable participants.
  - Mitigation: Implement a no-op participant pipeline or allow host to register participants via a simple API. Log disabled participants for visibility.
- Encoding and platform file API differences:
  - Risk: Text encoding conversions, BOM handling and atomic save semantics rely on low-level file APIs (fsync, atomic rename). Browser environments may not provide identical semantics.
  - Mitigation: Keep encoding conversion logic in portable JS modules and use feature-detected atomic-write helpers; for environments lacking atomic rename, fall back to safe-write with explicit overwrite confirmation.
- Save error UX / dialogs:
  - Risk: The save error handler uses platform dialog services and notification UI. Port may have different modal/dialog primitives.
  - Mitigation: Abstract dialog and confirmation APIs behind a small adapter that provides confirm/alert/input semantics in the host UI.
- Large-file memory & streaming:
  - Risk: Editors and save paths assume model can hold file in memory; very large files may break this.
  - Mitigation: Reuse the existing FileEditor/EditorInput design that supports readonly large file handling (open in binary viewer) and avoid loading huge files into text model — detect size and use streaming or a binary viewer (see [`binaryFileEditor.ts`](src/vs/workbench/contrib/files/browser/editors/binaryFileEditor.ts:1) — next to read).

Testing & validation targets
- Unit tests:
  - FileEditorInput.resolve/matching and encoding handling edge-cases.
  - Save error handler mapping: simulate file operation errors and assert presented actions.
  - Editor tracker backup scheduling: ensure dirty editors get backup calls on hot-exit.
- Integration tests:
  - Full save flow including save participants, progress reporting and save-as.
  - Hot-exit restore: start, edit, backup, simulate restart and verify restore/merge/reconcile flows.
  - Large-file guard: ensure very large files are opened using binary path or an explicit guard.
- Manual / E2E:
  - Behavior when storage/backups are not available.
  - Cross-platform behaviors: atomic save semantics and permission-denied scenarios.

Instrumentation & telemetry
- Save successes / failures with categorized error codes.
- Hot-exit backup counts and restore occurrences.
- Save participant durations and cancelations.

Implementation notes for porting
1. Start by porting minimal EditorInput and TextFileEditor wiring so open/save/edit flows work with a simple in-memory working copy.
2. Add a lightweight working copy service that: tracks dirty state, supports save() and backup(), and exposes events used by tracker and UI counters.
3. Implement a backup persistence adaptor: on web use IndexedDB or localStorage; on native use filesystem.
4. Implement the Save Error Handler adapter to use the host dialog/notification primitives.
5. After core path is working, port encoding, save participants and advanced reconcilers.

Next actions (automated)
- Create a feature doc that covers binary editor and large-file behaviors by reading:
  - [`src/vs/workbench/contrib/files/browser/editors/binaryFileEditor.ts:1`](src/vs/workbench/contrib/files/browser/editors/binaryFileEditor.ts:1)
- Expand to fileEditor registration wiring and any additional helpers (e.g., editor drag/open handlers) by reviewing other files in the folder.

End of file editors feature note.
