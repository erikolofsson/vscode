Chat widget & input — responsibilities and port notes

Summary:
This doc synthesizes the responsibilities, flows and porting considerations for the chat widget and input parts.

Responsibilities:
- Compose list UI and input editor that coordinates sending requests via the chat service and editing flows.
- Manage view model lifecycle, editing/checkpoint handling, followups, attachments, working set and implicit context.
- Coordinate progressive rendering, virtualization and dynamic heights for responses and embedded editors.

Key components & patterns:
- Chat widget: main composite that hosts the tree and input. See [`src/vs/workbench/contrib/chat/browser/chatWidget.ts:1`](src/vs/workbench/contrib/chat/browser/chatWidget.ts:1).
- Chat input part: embedded CodeEditor used as the input control with history, attachments, mode/model pickers and toolbars. See [`src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1).
- Code block / compare parts: pooled editors for codeblocks/diffs: [`src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1`](src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1).
- Attachment resolution & image handling: [`src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1).
- Chat editor (host in editor pane): [`src/vs/workbench/contrib/chat/browser/chatEditor.ts:1`](src/vs/workbench/contrib/chat/browser/chatEditor.ts:1).

UI & lifecycle patterns:
- WorkbenchObjectTree with supportDynamicHeights drives rendering; renderer notifies height changes and calls tree.updateElementHeight.
- Progressive/streaming responses create transient renderData on response view models; renderer uses diffIdentity to force rerenders while streaming.
- Input uses a pooled text model bound to a vscodeChatInput URI and holds a model reference so input model is not disposed unexpectedly.
- Editing/checkpoints: selecting a prior request sets a checkpoint on the chat model; the UI supports inline editing vs top-input editing based on configuration.

Editor pooling & embedded editors:
- Embedded code blocks and diffs obtain editor instances from pools (see `CodeBlockPart` and diff parts). Editors are reused and must be fully reset on release.
- Special URI schemes used for ephemeral models: `vscodeChatCodeBlock` and `vscodeChatCodeCompareBlock` (see the code block content provider in [`src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1`](src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1)).

Attachment & implicit context handling:
- Attachment model manages attachments Map and emits changes; input renders attachment widgets by kind (file, image, paste, tool, notebook output).
- Images may be read via fileService or web extractor and resized; image hashing is used for stable IDs (see related paste provider logic).
- The resolve service converts editor/resource/context drag-and-drop or clipboard data into chat variable entries (see [`src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1)).

Send / request flow:
- Input validates/adjusts agent prefix, applies prompt-file metadata, auto-attaches instructions, then calls IChatService.sendRequest with mode/model/tool options.
- Widget cancels previous requests for the session before sending and awaits response-created/response-complete promises to manage accessibility announcements and followups.

Porting considerations / risks:
1) Platform surface: heavy coupling to DI (IInstantiationService), model & editor services, Workbench tree/list, webviews, fileService, textModelService, progress, telemetry and context-key services. These must be provided or shimmed in the target platform.
2) Editor pooling correctness: pooled CodeEditor / DiffEditor lifecycles must fully clear decorations, listeners, providers and view state on release—otherwise stale editors leak DOM/listeners and produce visual corruption.
3) Progressive rendering: streaming chunking, hasSameContent checks, and requestAnimationFrame coalescing exist to avoid thrash. Reproduce throttling & ordering to match UX and to keep accessibility signals correct.
4) SHA1-based apply flow: text-edit apply uses SHA1 checks (DefaultModelSHA1Computer) and prompts on mismatch; port needs equivalent hashing and a clear UX for confirmation.
5) Attachments & privacy/security: remote image fetching, saving to workspace storage, and binary handling need secure policies and storage locations in the target product.
6) Accessibility: accessible alerts and the chat response accessible view (and timing windows to avoid noisy announcements) must be preserved for screen reader users.

Tests & validation:
- Unit tests and mocks for chat model, editor pools, text model service to simulate streaming responses and editor reuse.
- Visual/regression tests for tree dynamic heights, embedded editor render correctness and layout (input-on-top vs bottom).
- Integration tests for text-edit apply path including SHA mismatch dialog interaction.

Suggested short-term port checklist:
- Provide a minimal DI environment or adapters for modelService, textModelService, and editor widget creation.
- Implement an EditorPool abstraction with deterministic reset() and isStale() semantics used by content parts.
- Port or implement a lightweight virtual list with dynamic height support or adapt WorkbenchObjectTree semantics.
- Implement streaming response model and a progressive renderer that supports chunking/diffing and coalesced updates.
- Implement attachment pipeline (image resizing, hashing, storage) and the resolve service for drag/drop/clipboard.

Related source files:
- [`src/vs/workbench/contrib/chat/browser/chatWidget.ts:1`](src/vs/workbench/contrib/chat/browser/chatWidget.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1`](src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatEditor.ts:1`](src/vs/workbench/contrib/chat/browser/chatEditor.ts:1)

Open questions for the QA pass:
- Exact semantics of viewModel.setCheckpoint and undo-stop interactions across provider implementations.
- Test coverage mapping: where to add unit tests for EditorPool and for the DefaultChatTextEditor.apply SHA flow.
- How extension contribution points (chat participants, output renderers) should be exposed or adapted in the target platform.

Notes:
- This complements the existing product_description feature docs on codeblocks and text-edit/diff; during the QA pass we'll add cross-links, file line references and update MANIFEST.
