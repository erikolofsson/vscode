# Files — Host Adapter Stubs and API sketches

Purpose: Provide small adapter interfaces for hosts to implement core Files behaviors without VS Code internals. These are design sketches and example TypeScript signatures.

Location: product_description/features/files/adapters.md

Quick links:
- MANIFEST: [`product_description/MANIFEST.md:1`](product_description/MANIFEST.md:1)
- Editors deep dive: [`product_description/features/files/editors_deep_dive.md:1`](product_description/features/files/editors_deep_dive.md:1)

Summary:
- Provide adapters: BulkEditAdapter, FileWatcherAdapter, WorkingCopyAdapter, UploadAdapter, FileSystemAccessAdapter, ModelReferenceAdapter, EditorResolverAdapter.
- Each adapter maps a small set of responsibilities to host-provided primitives and must return Promises and Disposable for lifecycle management.
- Goal: make porting the Files contribution straightforward by isolating host-dependent behaviors behind small well-documented interfaces.

Design principles
- Minimal surface: keep APIs small, async, cancellable.
- Best-effort atomicity: expose undo token when available.
- Stream-friendly I/O: accept AsyncIterable<Uint8Array> for streams.
- Feature-detect host capabilities and fall back.

Adapter: BulkEditAdapter
Description: Apply multiple ResourceFileEdit-like operations atomically when possible; otherwise sequentially with best-effort undo.
Type signature (TypeScript):
interface BulkEditAdapter {
  apply(edits: ResourceFileEdit[], options?: { undoLabel?: string, token?: CancellationToken }): Promise<{ success: boolean; undoToken?: any; failed?: ResourceFileEdit[] }>;
  revert?(undoToken: any): Promise<boolean>;
}
Notes:
- ResourceFileEdit = { resource: URI, newResource?: URI, kind: 'create'|'move'|'copy'|'delete'|'update', contents?: AsyncIterable<Uint8Array>|Uint8Array|string, metadata?: any }
- If host supports atomic rename/move and metadata preservation, implement as atomic; otherwise perform create+copy+delete and return partial failures.
- Provide human-readable undoLabel for UI and telemetry.

Adapter: FileWatcherAdapter
Description: Host file system watcher with include/exclude support and debounced events.
Type signature:
interface FileWatcherAdapter {
  watch(root: URI, opts?: { recursive?: boolean, excludes?: string[], includes?: string[] }): Disposable;
  onDidChange?: Event<FileChangesEvent>;
  onDidError?: Event<{ error: Error }>;
}
Notes:
- Provide platform-specific backoff for ENOSPC-like errors and a re-scan capability.
- Expose ability to pause/resume watching for intensive operations (e.g., BulkEditAdapter.apply).

Adapter: WorkingCopyAdapter
Description: Expose editor dirty/backup/save model to the host so porters can query and control working copies.
Type signature:
interface WorkingCopyAdapter {
  isDirty(resource: URI): boolean;
  save(resource: URI, opts?: { force?: boolean, reason?: string, token?: CancellationToken }): Promise<boolean>;
  backup(resource: URI, token?: CancellationToken): Promise<URI|undefined>;
  revert(resource: URI, opts?: { force?: boolean }): Promise<void>;
  onDidChangeDirty: Event<URI>;
  onDidBackup: Event<{ resource: URI; backupResource: URI }>;
}
Notes:
- Backup returns a host-storable URI or undefined if not supported.
- Save should integrate with host's text model persistence and return success boolean.
- Expose events to allow host to coordinate hot-exit and shutdown.

Adapter: UploadAdapter
Description: Handle uploading browser File objects or streams into host workspace.
Type signature:
interface UploadAdapter {
  write(resource: URI, stream: AsyncIterable<Uint8Array>, opts?: { overwrite?: boolean, token?: CancellationToken }): Promise<void>;
  writeFileObject?(resource: URI, file: File, opts?: { token?: CancellationToken }): Promise<void>;
}
Notes:
- Prefer stream variant for large files. Feature-detect File.stream().
- Provide concurrency limits and progress callbacks via token or separate event.
- For hosts without streaming, implement buffered fallback with memory threshold and clear UX warnings.

Adapter: FileSystemAccessAdapter
Description: Provide host-native file picking / save dialogs and writable file streams where available.
Type signature:
interface FileSystemAccessAdapter {
  pickFolder?(opts?: { canCreate?: boolean, token?: CancellationToken }): Promise<URI|undefined>;
  pickFile?(opts?: { save?: boolean, defaultUri?: URI, token?: CancellationToken }): Promise<URI|undefined>;
  createWriteStream(uri: URI): Promise<{ write(chunk: Uint8Array): Promise<void>; close(): Promise<void> }>;
}
Notes:
- On web, implement via showDirectoryPicker()/FileSystemWritableFileStream when available; otherwise provide emulation via blob downloads.
- createWriteStream should support incremental writes (flush semantics) for large files.

Adapter: ModelReferenceAdapter
Description: Minimal model reference management for text buffers and their lifecycle.
Type signature:
interface ModelReferenceAdapter {
  acquire(resource: URI): Promise<{ model: TextModelLike; dispose(): void }>;
  onDidChangeContent?: Event<{ resource: URI }>;
}
Notes:
- TextModelLike should expose read/write and position/line APIs sufficient for text editors.
- Reference counting semantics help prevent premature model disposal during async operations.

Adapter: EditorResolverAdapter
Description: Allow host to plug alternate editors/viewers for resources (Open With...).
Type signature:
interface EditorResolverAdapter {
  getEditorsFor(resource: URI): Promise<EditorDescriptor[]>;
  open(resource: URI, editorId: string, opts?: { viewColumn?: number, preserveFocus?: boolean }): Promise<void>;
}
Notes:
- EditorDescriptor = { id: string; label: string; priority?: number; supports(resource?: URI): boolean }
- Use this adapter to implement "Open With..." workflows and to substitute binary viewers with text editors when requested.

Porting checklist (quick)
- Implement BulkEditAdapter before migrating rename/copy/paste flows.
- Provide a FileWatcherAdapter with pause/resume and re-scan.
- Ensure WorkingCopyAdapter supports backup & save hooks for hot-exit.
- Implement streaming UploadAdapter and FileSystemAccessAdapter fallbacks for web.

Example mapping notes
- VSCode IBulkEditService -> BulkEditAdapter
- VSCode IFileService watch -> FileWatcherAdapter
- VSCode ITextFileService -> WorkingCopyAdapter + ModelReferenceAdapter
- Browser File.stream() -> UploadAdapter.writeFileObject / write(stream)

Next steps
- Create small TypeScript shim templates under src/adapters/ for hosts to implement.
- Add unit-test proposals verifying best-effort undo semantics and stream correctness.

File created: [`product_description/features/files/adapters.md:1`](product_description/features/files/adapters.md:1)
