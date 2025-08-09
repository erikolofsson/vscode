# Markdown, Text-Edit/Diff, Progress, Attachments & Tool I/O (Chat)

Summary: Notes and porting considerations for chat markdown rendering, codeblock/editor pooling, text-edit/diff integration, progress parts, attachments rendering, and tool input/output UI.

Files reviewed:
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatMarkdownDecorationsRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownDecorationsRenderer.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:1`](src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:1)

Key responsibilities (per area)
- Markdown & codeblocks
  - The [`ChatMarkdownContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:66) composes the rendered markdown DOM using the platform [`MarkdownRenderer`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:22) and wires progressive rendering callbacks.
  - Codeblocks are handled either by embedding live editors (via pooled [`EditorPool`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:336)) or by showing collapsed code pills ([`CollapsedCodeBlock`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:377)).
  - Codeblock model lifecycle is integrated with `CodeBlockModelCollection` (ephemeral models + codemapper URIs) so editors can show, diff and map code blocks to file URIs.
  - The content part installs math/Katex support (optional via configuration) and wraps Katex blocks with horizontally scrollable containers.
  - Helpers: [`codeblockHasClosingBackticks`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:372) drives detection of incomplete fenced blocks.

- Editor & pooling
  - `EditorPool` (defined in [`chatMarkdownContentPart.ts`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:336)) is a `ResourcePool`-backed pool returning an [`IDisposableReference`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:71)-style object: { object, isStale(), dispose() }.
  - Pools are used across parts (lists/trees/diff editors) to reuse heavy DOM/editor instances and avoid re-creating editors continually.

- Text-edit / diff integration
  - [`ChatTextEditContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:44) renders text-edit diffs using a pooled diff editor (via `DiffEditorPool`) and obtains the compare model via the platform service interface [`ICodeCompareModelService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:37).
  - Implementation detail: [`CodeCompareModelService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:174) creates:
    - `original` model via `textModelService.createModelReference(uri)`,
    - `modified` model from a snapshot written into a new ephemeral model (scheme `vscodeChatCodeBlock`) and then replays prior edit groups by iterating the chat session requests and pushing edits into the modified model.
    - computes `originalSha1` using `DefaultModelSHA1Computer`.
    - returns a reference `{ originalSha1, original, modified }` wrapped in a `RefCountedDisposable` (short self-acquire for streaming scenarios).
  - Porting must reproduce model-ref creation, ephemeral model scheme, replay semantics, SHA1 compute and the confirmation/abort flow when applying edits from chat to real files.

- Progress & working indicator
  - [`ChatProgressContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:22) renders progress messages and optionally a spinner icon; it hides when other content follows.
  - [`ChatWorkingProgressContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:83) is a thin specialization to allow pause/resume UX hooks (click to resume).
  - Accessiblity: progress messages call `alert()` for SR when showing in-progress content.

- Attachments & contextual widgets
  - [`ChatAttachmentsContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:19) builds attached-context widgets from a list of `IChatRequestVariableEntry` items and instantiates type-specific widgets:
    - image: [`ImageAttachmentWidget`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1)
    - file: [`FileAttachmentWidget`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1)
    - prompt-file/text, paste, notebook outputs, SCM items, toolsets, etc.
  - Widgets receive a `ResourceLabels` helper for consistent icon/label rendering and the content part supports a `contextMenuHandler` for right-click operations and warning/omitted decorations.

- Tool Input/Output & save flow
  - [`ChatCollapsibleInputOutputContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:66) renders tool invocations that have structured input (code) and output (data blobs / files).
  - Outputs are exposed as downloadable resources with a toolbar/menu driven by `MenuWorkbenchToolBar` and a `SaveResourcesAction` (registered action) that:
    - prompts user for target location (`IFileDialogService`),
    - copies or reads/writes via `IFileService`,
    - shows progress via `IProgressService` and reveals in explorer (`REVEAL_IN_EXPLORER_COMMAND_ID`).

Important patterns to preserve when porting
- Pooling semantics:
  - All pools return an object with `isStale()` and `dispose()` semantics that must be preserved exactly to avoid DOM reuse races and leaks (see [`EditorPool.get()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:357)).
- Ephemeral model scheme & codemapper URIs:
  - Text-edit diffs and codeblock preview mapping rely on ephemeral URIs (e.g., `vscodeChatCodeBlock`) and codemapper URIs emitted by the `CodeBlockModelCollection`.
- Progressive rendering & isStale checks:
  - Chat renders progressively; pooled objects can become stale — UI renderers check `isStale()` to avoid updating disposed instances.
- Accessible labels & ResourceLabels:
  - UI uses `ResourceLabels` heavily for accessible strings and icon theming; a port needs an equivalent component.
- Quick input / nested pickers & background accepts:
  - Tooling and attach flows use quick-pick providers that can accept in background and support nested pickers (see attach/context flows in other docs). The attach flow also uses `resizeImage` on binary image payloads before attaching.

Porting risks and mitigations (top items)
1. Editor/diff pooling correctness (High)
   - Risk: leaking view state, decorations, or listeners when reusing editors.
   - Mitigation: Implement reset() semantics that clear decorations, view state and event listeners; add unit tests that acquire/release repeatedly and assert no leakage.

2. Model / SHA1 and apply semantics (High)
   - Risk: compute/verify sha1 mismatch across platforms or race when computing edits → data-loss risk when applying edits blindly.
   - Mitigation: replicate [`DefaultModelSHA1Computer`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:205) or compute server-side canonical SHA1; show explicit user-confirmation when mismatch found.

3. Streaming and progressive render ordering (Medium)
   - Risk: Out-of-order updates with pooled editors leading to visual corruption.
   - Mitigation: Implement `isStale()` checks, use request-scoped IDs and chunk ordering; reuse RefCountedDisposable patterns for model refs.

4. Attachments privacy & cleanup (Medium)
   - Risk: temporary files or stored images lingering on disk.
   - Mitigation: implement secure temp storage with TTL and cleanup job mirroring upstream (e.g., delete older than 7 days).

Tests to implement
- Unit:
  - Pool acquire/release lifecycle and reset() semantics.
  - [`CodeCompareModelService.createModel()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:184) behavior: original/modified model creation, sha1 compute, edit replay.
  - Attachments rendering variations, omitted/warning decorations.
- Integration:
  - Progressive markdown rendering with streaming codeblock updates (simulate partial content).
  - Tool I/O save flow: simulate file part(s) -> SaveResourcesAction path including folder vs single file save.
- Accessibility:
  - Progress announcements and ARIA labels for codeblock pills and attached items.

Cross-links
- Codeblock & editor pooling: [`product_description/features/chat/codeblocks.md:1`](product_description/features/chat/codeblocks.md:1)
- Text-edit/diff design: [`product_description/features/chat/textedit_diff.md:1`](product_description/features/chat/textedit_diff.md:1)
- Attachments & paste: [`product_description/features/chat/attachments_and_markdown.md:1`](product_description/features/chat/attachments_and_markdown.md:1)
- References & attach actions: [`product_description/features/chat/references_and_actions.md:1`](product_description/features/chat/references_and_actions.md:1)
- Markdown renderer & decorations: [`product_description/features/chat/markdown_and_io.md:1`](product_description/features/chat/markdown_and_io.md:1)
- Output renderer extensibility: [`product_description/features/chat/output_and_sessions.md:1`](product_description/features/chat/output_and_sessions.md:1)

References to important constructs (definitions & examples)
- [`ChatMarkdownContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:66)
- [`EditorPool`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:336)
- [`CollapsedCodeBlock`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:377)
- [`ChatTextEditContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:44)
- [`ICodeCompareModelService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:37)
- [`CodeCompareModelService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:174)
- [`DiffEditorPool`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:138)
- [`ChatProgressContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:22)
- [`ChatAttachmentsContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:19)
- [`ChatCollapsibleInputOutputContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:66)
- [`SaveResourcesAction`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:284)

Porting checklist (next concrete steps)
1. Implement a virtualized list/tree & ResourceLabels equivalent (UI primitives) — high priority.
2. Implement pooling primitives (`ResourcePool` + `IDisposableReference`) and pattern tests — high.
3. Provide text model service and ephemeral model creation with snapshot and SHA1 compute — high.
4. Implement editor/diff embedding & reset semantics for pooled editors — high.
5. Wire file read/resize utilities and secure temporary storage for attachments — medium.
6. Recreate quick-pick provider hooks for attach/context flows and tool IO menus — medium.
7. Add tests (unit/integration) for pooling, compare-model creation, and save resources flow — medium.

End of document.
