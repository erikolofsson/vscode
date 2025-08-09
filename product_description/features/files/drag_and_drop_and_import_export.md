# Files: Drag & Drop, Upload & Download

Summary:

This document synthesizes responsibilities and porting notes for the explorer import/export flows:
- [`src/vs/workbench/contrib/files/browser/fileImportExport.ts:1`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:1)

Responsibilities

- BrowserFileUpload (class) — handles uploads from drag & drop and input: streaming via File.stream, chunked writes through [`newWriteableBufferStream()`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:316), concurrency via [`Limiter`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:15), progress scheduling via [`RunOnceWorker`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:148).
- ExternalFileImport (class) — handles external file/folder drops, activates providers, resolves resources, and offers Add vs Copy when dropping folders; copies via bulk edits (`ResourceFileEdit`).
- FileDownload (class) — downloads files/folders for web and native, choosing between Web File System Access APIs (`WebFileSystemAccess`) and blob/download fallbacks, streaming reads via [`readFileStream()`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:702) when available.

Upload flow details

- Entry point: [`BrowserFileUpload.upload()`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:85) creates a cancellation token and reports progress. It converts the source into a webkit-style transfer via [`toTransfer()`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:106).
- Main worker: [`BrowserFileUpload.doUpload()`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:134) copies entries into an owned array, creates an operation object, and uses a [`Limiter`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:158) to bound parallel uploads.
- Per-entry handling: [`BrowserFileUpload.doUploadEntry()`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:199) branches between file vs folder, confirms overwrites, and chooses:
  - Buffered streaming: [`doUploadFileBuffered()`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:309) uses File.stream() and writes to [`newWriteableBufferStream()`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:316).
  - Unbuffered fallback: [`doUploadFileUnbuffered()`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:356) uses FileReader to read ArrayBuffer and write as a single buffer.
- Folder uploads recurse using webkit entry readers and split file/folder children; files are uploaded with bounded concurrency while folders are processed sequentially.

Import / Workspace-add

- External drops call [`ExternalFileImport.import()`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:404) which activates providers, resolves dropped resources, and for folder drops offers a prompt: Add to workspace vs Copy into workspace.
- Copy operations use the bulk-edit API via [`ExplorerService.applyBulkEdit()`](src/vs/workbench/contrib/files/browser/explorerService.ts:184) with `ResourceFileEdit` entries so undo/redo metadata and progress integrate with the explorer.

Download flow details

- Entry point: [`FileDownload.download()`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:606) reports progress and iterates sources.
- Web strategy: prefer Web File System Access for folders or large files (`WebFileSystemAccess.supported`) and stream using [`readFileStream()`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:702) into FileSystemWritableFileStream handles; fall back to blob or URL download for small files via [`triggerDownload()`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:26).
- Native strategy: prompts via [`IFileDialogService.showSaveDialog()`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:828) and then performs a bulk copy (`ResourceFileEdit`) to the destination so the host can manage actual file writes and preserve metadata.

Progress & cancellation

- All long-running flows are wrapped in `progressService.withProgress` and use `CancellationTokenSource` to support cancellation. Progress messages are throttled using `RunOnceWorker` and include throughput estimates (bytes/sec) for uploads and downloads.

Important porting risks & mitigations

- Browser FS APIs variability: File.stream(), webkitGetAsEntry(), and Web File System Access may be missing in some hosts. Mitigation: keep both streaming and buffered code paths as in [`doUploadEntry()`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:199) and feature-detect (`WebFileSystemAccess.supported`) before using FS handles.
- Memory pressure on large blobs: the code avoids blob-download for >32MB and prefers streaming. Port must preserve thresholds and streaming when possible.
- Bulk-edit dependency: import/copy/download use `ResourceFileEdit` + `IBulkEditService` for atomicity and undo; hosts without bulk-edit need an adapter providing atomic operations or best-effort sequences with undo metadata.
- Permissions & provider activation: dropped resources may reference remote schemes requiring provider activation (`fileService.activateProvider`). Ensure dynamic activation or graceful fallback.

Porting adapters to implement

- UploadAdapter: wraps file writes, supports stream writes and fallback, surfaces per-file progress and cancellation.
- FileSystemAccessAdapter: exposes chooser dialogs (directory picker / save) and FileSystemWritableFileStream shims when running in constrained environments.
- BulkEditAdapter: applies ResourceFileEdit batches with progress, undo labels, and confirm-before-undo semantics.
- DnDEntryParser: emulate webkit entry iteration when not available (e.g., iterate FileList and reconstruct directory entries or call server-assisted upload).

Testing proposals

- Unit tests:
  - [`incrementFileName()` behavior](src/vs/workbench/contrib/files/browser/fileActions.ts:364) for conflict resolution across naming strategies.
  - Upload logic switches (buffered vs unbuffered) in [`doUploadEntry()`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:199).
- Integration tests:
  - Drag & drop nested folder upload with mixed small/large files and overwrite prompts.
  - External folder drop causing "Add to workspace" vs "Copy" prompt and correct workspace editing.
- E2E:
  - Download of large folder via WebFileSystemAccess and fallback to blob for small files; ensure memory usage stays bounded.

Next steps

1. Create detailed adapter stubs for hosts without streaming or bulk-edit capabilities.
2. Add doc cross-links from [`product_description/features/files/import_and_export.md:1`](product_description/features/files/import_and_export.md:1) to this deep-dive.
3. Continue reading remaining files in [`src/vs/workbench/contrib/files/browser/editors/:1`](src/vs/workbench/contrib/files/browser/editors/:1) for any upload/download interactions.

Owner: Kilo Code

End.
