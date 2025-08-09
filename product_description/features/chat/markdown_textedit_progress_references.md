# Chat: Markdown, Text-Edit, Progress & References — Responsibilities and Porting Notes

Files analyzed
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:1)

Summary
The chat UI contains several content-part implementations responsible for rendering markdown (with codeblocks), computing and displaying text-edit diffs, progressive/working progress UI, multi-file diffs and collapsible reference lists. This document captures responsibilities, injected services, lifecycle patterns, critical invariants and porting notes for these parts.

1) chatMarkdownContentPart.ts — responsibilities & patterns
- Renders markdown responses using a shared MarkdownRenderer and conditionally wires Katex/math support.
- Produces codeblock subparts using CodeBlockPart (full editor) or CollapsedCodeBlock (pill) and coordinates with CodeBlockModelCollection.
- Acquires code editors from EditorPool (a ResourcePool) and returns IDisposableReference wrappers that supply isStale()/dispose() semantics and call reset() on release.
- Emits onDidChangeHeight when rendered content or codeblock heights change; uses ResizeObserver for certain math blocks.
- Key helpers/algorithms:
  - codeBlockRendererSync callback that creates either a live editor or a collapsed pill depending on state and availability of codemapperUri.
  - codeblockHasClosingBackticks to detect incomplete blocks during streaming.
  - codeblocks list holds IChatCodeBlockInfo entries with uriPromise for asynchronous codemapperUri resolution.
- Important invariant: editors returned via EditorPool.get() must be reset before reuse and IDisposableReference.isStale must true after dispose() to prevent reuse-after-release.

Injected services (representative)
- [`ITextModelService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:92)
- [`IInstantiationService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:93)
- [`IContextKeyService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:90)
- [`IConfigurationService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:91)
- CodeBlockModelCollection, EditorPool

Port notes / risks (markdown)
- Provide a MarkdownRenderer equivalent that supports:
  - sanitizerConfig and allowedTags,
  - a synchronous codeBlockRendererSync callback that can create DOM nodes or editor placeholders,
  - an asyncRenderCallback to notify layout changes.
- Preserve ResourcePool / EditorPool semantics: get() → use → object.reset() → release(); ensure IDisposableReference shape with isStale() check.
- CodeBlockModelCollection must be ported: session-scoped codeblocks, async update/resolve producing codemapperUri, and mapping from responseId → codeblock info.
- Katex/math integration: load support asynchronously and dispatch layout resize participants; do not block initial markdown render.
- Maintain accessibility contracts: aria labels and focus() behavior on codeblock parts.

2) chatTextEditContentPart.ts — responsibilities & patterns
- Renders text-edit groups either as a human-readable summary (when configured) or as a CodeCompareBlockPart (diff editor).
- Uses DiffEditorPool (ResourcePool) to reuse heavy diff editors; dependencies include ICodeCompareModelService that creates original and modified models.
- createModel flow (CodeCompareModelService):
  - createModelReference(originalUri) to obtain original model reference (reference-counted).
  - Create a modified model by snapshotting the original and calling modelService.createModel(...) with scheme Schemas.vscodeChatCodeBlock and a unique query.
  - Compute original SHA1 (DefaultModelSHA1Computer) and persist in chatTextEdit.state if not present.
  - Replay previous edits (from prior requests) onto the modified model to reach current state.
  - Self-acquire a RefCountedDisposable and release after a short timeout (5000ms) to favor reuse during streaming updates.
- The comparePart's diffData is asynchronous: UI waits for the model creation promise to resolve before rendering full diff.

Injected services (representative)
- [`ITextModelService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:179)
- [`IModelService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:180)
- [`IChatService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:181)

Port notes / risks (text-edit)
- Host must support:
  - transient text model creation with a custom scheme (vscodeChatCodeBlock) and unique URIs,
  - createModelReference/ref-count semantics,
  - model snapshot → createModel workflow and reliable pushEditOperations semantics.
- SHA1 computation should be preserved (or replaced with a compatible integrity check) because logic stores and relies on originalSha1.
- Edit replay order and idempotence are critical: replay all prior edits up to the response being rendered.
- Keep or emulate the self-acquire + timeout pattern to avoid premature model disposal during streaming; this is important for reusing modified models for subsequent progressive updates.

3) chatProgressContentPart.ts — responsibilities & patterns
- Renders progress messages and working indicators (IChatProgressMessage / IChatWorkingProgress).
- Decides visibility using following content and response completeness:
  - shouldShowSpinner(followingContent, element) returns true for streaming responses that are not complete and have no following content.
- When spinner is shown, an ARIA alert is emitted (alert(progress.content.value)) for screen-reader users.
- Renders progress content via MarkdownRenderer and supports inline file widgets through renderFileWidgets.

Injected services (representative)
- [`IChatMarkdownAnchorService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:36)
- [`IInstantiationService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:35)

Port notes / risks (progress)
- Progressive/hide semantics must be enforced by the renderer: progress parts act as placeholders until non-progress content appears, then they should be hidden (rerender required).
- Spinner heuristics depend on response.isComplete and the absence of following content. Platform timing differences (event loop, task scheduling) will affect behavior; make spinner logic configurable.
- Ensure the host provides an ARIA alert mechanism equivalent to alert(...) used here for SR notifications.

4) chatMultiDiffContentPart.ts — responsibilities & patterns
- Renders a compact summary of multiple file changes and provides a collapsible list of changed files.
- Integrates with WorkbenchList and MultiDiffEditorInput to open a grouped multi-diff view.
- Provides a "view all file changes" button that constructs a MultiDiffEditorInput and opens it in the active editor group.

Injected services (representative)
- [`IInstantiationService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:54)
- [`IEditorService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:55)
- [`IEditorGroupsService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:56)

Port notes / risks (multi-diff)
- Provide a list widget with click/open events and an editor abstraction that supports a grouped multi-diff input. If not available, fallback to opening individual diffs/files.
- Preserve accessibility/keyboard interactions and the ability to compute a stable identity for list items.

5) chatReferencesContentPart.ts — responsibilities & patterns
- Renders collapsible lists of references and warnings using WorkbenchList and ResourceLabels.
- Integrates rich context menus, per-item toolbars (MenuWorkbenchToolBar), and DnD to fill editors drag data.
- Special-cases: GitHub URIs, settings URIs, mail/http links, kernel variables and strikethrough/excluded presentation.
- Uses CollapsibleListPool (ResourcePool) to reuse list instances; templates create scoped IContextKeyService instances for item toolbars.

Injected services (representative)
- [`IInstantiationService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:70)
- [`IOpenerService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:68)
- [`IMenuService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:69)
- [`IContextMenuService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:71)
- Label/Theme/Resource services (ResourceLabels, ILabelService, IThemeService)

Port notes / risks (references)
- Menu/toolbar/context-key integration is heavy; port needs a menu system compatible with MenuWorkbenchToolBar and menu ids used here (MenuId.ChatAttachmentsContext and others).
- ResourceLabels and file icon theming provide consistent UI; replicate or provide a simplified label renderer and theming adapter.
- Drag-and-drop uses fillEditorsDragData to populate editor drag payloads — maintain the DnD contract for editor open flows or create a platform-specific adapter.

Cross-cutting patterns and invariants
- ResourcePool pattern (see chatCollections.js) is used extensively. Preserve:
  - get() returns IDisposableReference { object, isStale(): boolean, dispose(): void }.
  - On dispose(), object.reset() is called and the pool.release(object) is invoked.
  - Consumer code relies on isStale() becoming true after dispose() to detect invalid references.
- Progressive rendering & streaming:
  - Several parts rely on streaming updates and incremental re-renders. Host must provide deterministic update ordering and a way to compute "followingContent".
  - Timing heuristics (progress spinner, progressive word counts) are sensitive — expose config knobs for tuning.
- Transient model URIs:
  - Code-block and diff models use custom schemes (Schemas.vscodeChatCodeBlock) and unique queries to avoid collisions and to map editors.
  - Host must support creating transient models and ref-counted model references.
- Accessibility:
  - ARIA alerts for progress, keyboard focusability for pills and lists, and explicit focus() hooks on parts must be preserved.

Recommended tests to add/retain (unit/integration)
- ResourcePool lifecycle test: acquire → release sets isStale() true, reset() called, reuse resets state.
- CodeCompareModelService tests: originalSha1 computed for new models; replayed edits produce expected modified model content.
- Progressive hiding test: progressMessage parts hide when subsequent non-progress content appears.
- CodeBlock rendering: codeblock codemapperUri resolves correctly and editors render when uriPromise resolves.
- Multi-diff opener test: creating MultiDiffEditorInput opens expected items and retains transient source URI.
- Reference list context menu & DnD tests: menu actions behave as expected (AddToChat, CopyLink, Open).

Migration checklist (practical steps for port)
1. Implement/adapt a MarkdownRenderer with codeBlockRenderer hooks, sanitizer config and async callbacks.
2. Implement ResourcePool and IDisposableReference semantics exactly as in chatCollections.
3. Provide model service features:
   - createModelReference(uri) returning ref-counted model references
   - modelService.createModel from snapshot with a custom scheme
   - compute model SHA1 or provide replacement
4. Provide List/Toolbar/Menu APIs or adapters for WorkbenchList, MenuWorkbenchToolBar and the MenuId usage.
5. Recreate CodeBlockModelCollection behavior and editor open handlers for codeblock URIs.
6. Add accessibility behaviors (aria alerts, keyboard handling) and test with screen-readers.

Appendix — notable code locations (quick links)
- CodeCompareModelService: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:174`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:174)
- EditorPool.get/reset/release: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:336`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:336)
- Progress spinner heuristic: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:79`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:79)
- Collapsible list and context menu wiring: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:102`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:102)

End.
