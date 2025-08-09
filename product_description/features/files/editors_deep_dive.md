# Files: Editors (Text & Binary) Deep Dive

Summary:

- This document synthesizes the editor-side implementation for files: text editors, binary fallback, editor input/serialization, and working-copy tracking.
- Source files summarized:
  - [`src/vs/workbench/contrib/files/browser/editors/binaryFileEditor.ts:1`](src/vs/workbench/contrib/files/browser/editors/binaryFileEditor.ts:1)
  - [`src/vs/workbench/contrib/files/browser/editors/fileEditorHandler.ts:1`](src/vs/workbench/contrib/files/browser/editors/fileEditorHandler.ts:1)
  - [`src/vs/workbench/contrib/files/browser/editors/fileEditorInput.ts:1`](src/vs/workbench/contrib/files/browser/editors/fileEditorInput.ts:1)
  - [`src/vs/workbench/contrib/files/browser/editors/textFileEditor.ts:1`](src/vs/workbench/contrib/files/browser/editors/textFileEditor.ts:1)
  - [`src/vs/workbench/contrib/files/browser/editors/textFileEditorTracker.ts:1`](src/vs/workbench/contrib/files/browser/editors/textFileEditorTracker.ts:1)

Responsibilities

- FileEditorInput: canonical representation of a file in the editor layer. Manages preferred metadata (name/description/encoding/language/contents), resolves text vs binary models, exposes capabilities (readonly, untitled), tracks model references and lifecycle. See [`fileEditorInput.ts:39`](src/vs/workbench/contrib/files/browser/editors/fileEditorInput.ts:39).

- TextFileEditor: UI code editor that binds to text file models, restores view state, handles binary/too-large/directory errors and delegates open-as-binary logic. Integrates with host events to clear/move view state on file changes. See [`textFileEditor.ts:44`](src/vs/workbench/contrib/files/browser/editors/textFileEditor.ts:44).

- BinaryFileEditor: fallback viewer for binary or undecodable files; integrates with editor-resolver service to let user reopen as text or pick another editor. See [`binaryFileEditor.ts:23`](src/vs/workbench/contrib/files/browser/editors/binaryFileEditor.ts:23).

- FileEditorHandler (serializer + working-copy handler): serializes FileEditorInput for storage/restoration and implements IWorkingCopyEditorHandler to map working-copies to editors and create editor inputs as needed. See [`fileEditorHandler.ts:28`](src/vs/workbench/contrib/files/browser/editors/fileEditorHandler.ts:28).

- TextFileEditorTracker: workbench contribution that ensures dirty/untitled text models are opened in editors, reloads visible editors on window focus, and keeps the UX consistent for pending saves/auto-save. See [`textFileEditorTracker.ts:23`](src/vs/workbench/contrib/files/browser/editors/textFileEditorTracker.ts:23).

Key behaviors & patterns

- Resolve/Model separation:
  - The input resolves to either a text model or a binary model. `FileEditorInput.resolve()` first attempts text resolution (with preferences) then falls back to binary on FILE_IS_BINARY errors. Preserve this two-stage resolve to avoid creating large text models for binary content. See [`fileEditorInput.ts:338`](src/vs/workbench/contrib/files/browser/editors/fileEditorInput.ts:338).

- Force-open hints:
  - Preferred encoding, language, or provided contents set on the input are used as hints and call `setForceOpenAsText()` to bias resolution. Implementations must allow user/host to set these preferences before resolve. See [`fileEditorInput.ts:262`](src/vs/workbench/contrib/files/browser/editors/fileEditorInput.ts:262).

- Editor chooser & resolution:
  - `BinaryFileEditor` uses the editorResolverService to show the "Open With..." flow, possibly reopening the file as text or in another editor. Preserve resolver integration or provide a UX alternative for editor selection. See [`binaryFileEditor.ts:62`](src/vs/workbench/contrib/files/browser/editors/binaryFileEditor.ts:62).

- View state management:
  - `TextFileEditor` stores and moves view state when files are moved/deleted and restores view state when opening. Keep mapping from resource → viewState and update on FileOperationEvent. See [`textFileEditor.ts:71`](src/vs/workbench/contrib/files/browser/editors/textFileEditor.ts:71).

- Serialization and restoration:
  - `FileEditorInputSerializer` serializes resource, preferred resource, encoding, language and label metadata for workspace/session restore. Important to preserve to support window restore. See [`fileEditorHandler.ts:34`](src/vs/workbench/contrib/files/browser/editors/fileEditorHandler.ts:34).

- Working-copy integration:
  - `FileEditorWorkingCopyEditorHandler` maps working copies to editor inputs so the working-copy framework can open editors for dirty models. Implement a similar hook or adapter to map host working-copy abstractions to editors. See [`fileEditorHandler.ts:70`](src/vs/workbench/contrib/files/browser/editors/fileEditorHandler.ts:70).

Porting risks & mitigations

- Large/binary file handling:
  - Risk: creating large text models for binary files or huge files can exhaust memory. The code uses resolver limits and throws TooLargeFileOperationError to gate that. Maintain size thresholds and the text-vs-binary detection flow. See [`textFileEditor.ts:195`](src/vs/workbench/contrib/files/browser/editors/textFileEditor.ts:195).

- Model reference leaks:
  - Risk: cached model references must be disposed when inputs are disposed to avoid leaks. `FileEditorInput.dispose()` clears model refs. Ensure host has reference-counted model lifecycles or adapt. See [`fileEditorInput.ts:469`](src/vs/workbench/contrib/files/browser/editors/fileEditorInput.ts:469).

- Editor resolver dependency:
  - Risk: BinaryFileEditor depends on editorResolverService and EditorResolution.PICK UI. If host lacks a resolver, provide a simple fallback: open as text (with warning) or present a basic chooser UI.

- Working-copy & restore integration:
  - Risk: workbench relies on IWorkingCopyEditorService for ensuring dirty models are opened. If host lacks this, implement a tracker that watches dirty models and opens transient editors or surfaces a notification.

Key code snippets (representative)

- Two-stage resolve with binary fallback:
  - [`fileEditorInput.ts:338`](src/vs/workbench/contrib/files/browser/editors/fileEditorInput.ts:338)

- Open-as-binary vs reopen-as-text flow:
  - [`textFileEditor.ts:242`](src/vs/workbench/contrib/files/browser/editors/textFileEditor.ts:242)
  - [`binaryFileEditor.ts:62`](src/vs/workbench/contrib/files/browser/editors/binaryFileEditor.ts:62)

- Ensure dirty files are opened worker:
  - [`textFileEditorTracker.ts:57`](src/vs/workbench/contrib/files/browser/editors/textFileEditorTracker.ts:57)

Recommended host adapters

- ModelReferenceAdapter: a reference-counted text-model service that supports createModelReference(uri) and returns objects with .object and .dispose() so inputs can cache and release.

- EditorResolverFallback: a simple resolver UI or API to select alternative editors when a binary file is encountered.

- WorkingCopyBridge: expose dirty working-copy events and a way to determine/find an editor for a model; used by the tracker to open editors for dirty models.

Tests & QA

- Unit:
  - Input resolve: simulate FILE_IS_BINARY and TooLarge errors and assert fallback to binary model.
  - Serializer: round-trip serialize/deserialize of `FileEditorInput`.

- Integration:
  - Open a file, change encoding/language via input preferences, and verify resolved model honors hints.
  - Rename/move file and ensure view-state is moved and restored.

Next steps

1. Cross-link this doc from [`product_description/features/files/editors.md:1`](product_description/features/files/editors.md:1).
2. Create adapter stubs (`ModelReferenceAdapter`, `EditorResolverFallback`) in the porting checklist and provide examples.
3. Continue to QA pass: run through the files feature docs and update MANIFEST.

Owner: Kilo Code

End.
