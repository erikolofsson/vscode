# Import & Export — Feature detail

This document synthesizes the browser and native import/export (drag & drop, upload, download) flows implemented in the Files contribution.

Files read for this section
- [`src/vs/workbench/contrib/files/browser/fileImportExport.ts:1`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:1)
- [`src/vs/workbench/contrib/files/browser/editors/binaryFileEditor.ts:1`](src/vs/workbench/contrib/files/browser/editors/binaryFileEditor.ts:1)

Primary responsibilities
- Accept native drag & drop and input-based uploads (browser).
- Import external files/folders into the workspace or copy them into a target folder.
- Provide a buffered streaming upload path for large files and a fallback for small files.
- Download files and folders using Web File System Access where available or blob-download fallback; native path uses save dialog and bulk edit copy.
- Surface progress, cancellation and conflict/overwrite UX consistently.

Key implementations
- Browser uploads and drag/drop conversion: [`src/vs/workbench/contrib/files/browser/fileImportExport.ts:72`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:72) (class BrowserFileUpload)
- External file import (drag & drop from OS / other windows): [`src/vs/workbench/contrib/files/browser/fileImportExport.ts:387`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:387) (class ExternalFileImport)
- Download logic, WebFileSystemAccess vs blob fallback, native save dialog: [`src/vs/workbench/contrib/files/browser/fileImportExport.ts:592`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:592) (class FileDownload)

Browser upload flow (BrowserFileUpload)
- Accepts a DragEvent or FileList and normalizes to a webkit-style data transfer (`toTransfer`).
- Performs parallel uploads with a concurrency limiter (MAX_PARALLEL_UPLOADS = 20) and a RunOnceWorker to throttle progress updates.
- For files larger than 1MB and when File.stream is available, uses a streaming buffered upload path (`doUploadFileBuffered`) that writes to a VSBuffer stream and calls `fileService.writeFile` with an async stream.
- For small files or browsers without streaming support, uses FileReader and writes the entire ArrayBuffer to `fileService.writeFile` (`doUploadFileUnbuffered`).
- Supports recursive folder uploads by reading directory entries (webkit entry API), creating folder targets via `fileService.createFolder`, and enqueueing child uploads.
- Confirms overwrite per-file with `dialogService.confirm` when target already contains an entry; supports applying an immediate overwrite via `explorerService.applyBulkEdit`.
- Reports per-file and aggregate progress, including bytes/sec estimates.

External import flow (ExternalFileImport)
- Extracts dropped editors/files via DnD utilities and activates file providers for their schemes.
- Resolves dropped resources; supports two primary actions for dropped folders into a workspace root: Add to workspace or Copy into workspace (user choice).
- For copying resources, performs preflight existence checks, prompts for overwrite when necessary and uses `explorerService.applyBulkEdit` with ResourceFileEdit(copy) to perform the copy with undo/confirmation semantics.
- Optionally auto-opens a single imported file depending on configuration (`explorer.autoOpenDroppedFile`).

Download flow (FileDownload)
- Runs per-item download logic with progress and cancellation.
- Browser behavior:
  - For directories or files larger than a threshold (32 MB), prefer Web File System Access APIs to write files/folders into a picked directory (`showDirectoryPicker`).
  - For files under the blob threshold, attempt to read via `fileService.readFile(..., limits)` into a buffer and trigger a browser download via `triggerDownload`; on error, fall back to file-accessible URL via `FileAccess.uriToBrowserUri`.
  - When using File System Access, the code streams reads (`readFileStream`) and writes to the selected handle using buffered/unbuffered strategies depending on file size.
- Native behavior:
  - Uses file save dialog (`fileDialogService.showSaveDialog`) with a remembered last-download folder stored in storage service.
  - Performs a `ResourceFileEdit` copy to the selected destination using `explorerService.applyBulkEdit`.

UX & Progress
- Global progress is shown via IProgressService (Window location) and also localized progress in the Explorer view.
- Operations are cancellable (CancellationTokenSource) and the code ensures cancellation propagates through streams and queued uploads.
- Overwrite/conflict prompts use helper functions `getFileOverwriteConfirm` and `getMultipleFilesOverwriteConfirm`.

Platform distinctions & feature detection
- Uses feature detection for:
  - File.stream() presence and file.size thresholds to choose streaming uploads vs readAsArrayBuffer.
  - Web File System Access availability (`WebFileSystemAccess.supported`) to decide between directory download APIs vs blob-download fallback.
  - isWeb platform check to gate download cancellability and upload strategies.

Porting risks & mitigations
- Browser APIs (File.stream, webkit dataTransfer entries, File System Access) are not universally available.
  - Mitigation: keep both buffered and unbuffered paths; feature-detect and fallback to blob downloads or server-assisted transfers if streaming/FS API is unavailable.
- Directory entry APIs (webkitGetAsEntry) are non-standard.
  - Mitigation: implement an adapter that normalizes incoming drag&drop payloads; where impossible, restrict to FileList uploads only.
- Large-file memory pressure when using blob-download trick or reading entire file into memory.
  - Mitigation: use streaming APIs when available; enforce thresholds (e.g., 32MB) and surface warnings or block if not supported.
- Overwrite confirmation consistency across native & web.
  - Mitigation: centralize confirmation helpers (`getFileOverwriteConfirm`) and reuse them; ensure platform dialogs map correctly to host UI.

Testing & validation recommendations
- Unit tests:
  - Upload: simulate File objects with stream and without; test buffered vs unbuffered paths, progress updates, cancellation.
  - Import: test file-provider activation and bulk-edit copy creation on name collisions.
  - Download: simulate fileService.readFile throwing for large files and ensure fallback to uri path.
- Integration/E2E:
  - Drag & drop folder import on web with File System Access supported and unsupported.
  - Download folder in browser via showDirectoryPicker and verify created files.

Implementation guidance for porting
1. Provide a small adapter for DnD payloads that can present a normalized "entry" API (isDirectory/isFile/file()/readEntries()) to the existing BrowserFileUpload code or create a simplified FileList-only pathway.
2. Implement a streaming write adapter for the host's file service that mirrors `newWriteableBufferStream` semantics (write, end, error) so `doUploadFileBuffered` can be reused.
3. If host lacks File System Access, implement a server transfer endpoint or a native save dialog fallback to handle directories and large files.
4. Preserve the overwrite confirmation helpers and bulk-edit semantics to keep undo/redo behavior after import/export operations.

Cross-links to other features
- FileEditor large-file handling: [`src/vs/workbench/contrib/files/browser/editors/binaryFileEditor.ts:23`](src/vs/workbench/contrib/files/browser/editors/binaryFileEditor.ts:23)
- Explorer applyBulkEdit usage for copy/overwrite flows used throughout: see other files such as [`src/vs/workbench/contrib/files/browser/fileActions.ts:1`](src/vs/workbench/contrib/files/browser/fileActions.ts:1)

Next actions (automated)
- Produce final cross-linking and update the files MANIFEST entry to include:
  - explorer_and_file_actions.md
  - views_and_viewer.md
  - editors.md
  - import_and_export.md (this file)
- Continue with any remaining helper files (decorations, media) and then perform QA pass across all files docs.

End of document.
