# Markdown, Text-Edit, Progress & Attachments — Chat subsystem

Summary:
- This document synthesizes responsibilities, lifecycle patterns, call-sites, injected services, UI flows, and porting considerations for markdown rendering, code-blocks, text-edit/diff integration, progress rendering, and attachment widgets.

Related implementation files:
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1)

Overview:
- chatMarkdown: handles markdown rendering (with sanitizer), inline anchors, code-block lifecycle, Katex/math support, and progressive rendering for streaming responses.
- text-edit/diff: constructs compare models (original + modified) via model snapshot + replayed edits, produces diff editors via pooled diff editor parts.
- progress: renders progressive/working messages, decides spinner visibility and accessibility announcements.
- attachments: selects appropriate widget for each attachment entry kind and wires up opener/drag/context-menu/clear semantics.

Key responsibilities & behaviors

ChatMarkdownContentPart
- Wraps Editor/MarkdownRenderer and configures sanitizer options and Katex extensions.
  - Uses `MarkdownRenderer.render(..., { sanitizerConfig: ... })` and wraps markdown body to preserve leading comments.
  - Ensures remote images are blocked and allowed tags are limited (see allowedChatMarkdownHtmlTags).
- Code block handling:
  - Synchronous code block render path (codeBlockRendererSync) for small or local-file blocks.
  - Uses `EditorPool` to get pooled `CodeBlockPart` instances (IDisposableReference pattern).
  - Creates or updates entries in `CodeBlockModelCollection` to track ephemeral models and codemapper URIs.
  - For streaming responses, supports rendering “pills” (CollapsedCodeBlock) while async codemapper URIs are computed.
- Layout & sizing:
  - Listens to codeblock content height changes (onDidChangeContentHeight) to fire part-level onDidChangeHeight.
  - Uses ResizeObserver and DomScrollableElement to handle katex display blocks.
- Accessibility:
  - Ensures text nodes are normalized into <p> elements when needed and registers hover titles as managed hovers.

ChatTextEditContentPart
- Renders text-edit groups as a CodeCompareBlock via a pooled `CodeCompareBlockPart` (DiffEditorPool).
- Key model construction performed by `CodeCompareModelService.createModel(...)`:
  - Acquire original model ref: `textModelService.createModelReference(uri)`.
  - Create modified model from snapshot: `createTextBufferFactoryFromSnapshot(original)` → new model with ephemeral URI (scheme `vscodeChatCodeBlock`).
  - Compute original SHA1 using `DefaultModelSHA1Computer` when not available in state.
  - Replay prior edits collected from the chat session requests into the modified model (pushEditOperations).
  - Return a RefCountedDisposable-like reference object containing originalSha1 + original/modified models.
  - Temporarily self-acquire the returned disposable (d.acquire(); setTimeout(() => d.release(), 5000)) to favor reuse during streaming and avoid premature release.
- Diff editor pool lifecycle mirrors EditorPool: get() returns IDisposableReference and dispose resets/release.

ChatProgressContentPart
- Renders progress messages (IChatProgressMessage or IChatTask) and working-progress.
- Spinner visibility logic:
  - Uses shouldShowSpinner(followingContent, element) which is true for streaming responses with no following content.
  - Uses alert(...) to notify screen-reader users when a spinnered progress step is shown.
- Renders file widgets inside progress messages using renderFileWidgets and coordinates with chatMarkdownAnchorService for inline anchors.
- Hides progress messages when subsequent non-progress content appears (hasSameContent checks include followingContent).

ChatAttachmentsContentPart
- Initializes attachment widgets per `IChatRequestVariableEntry`:
  - ImageAttachmentWidget, FileAttachmentWidget, PasteAttachmentWidget, PromptFileAttachmentWidget, PromptTextAttachmentWidget, ElementChatAttachmentWidget, SCMHistoryItemAttachmentWidget, ToolSetOrToolItemAttachmentWidget, DefaultChatAttachmentWidget.
- Creates ResourceLabels with visibility hooks and uses `createInstantHoverDelegate()` for hover content.
- Propagates omitted/partial states from contentReferences into widget visuals (warning class, aria).
- Hooks contextmenu events to a higher-level contextMenuHandler for menu wiring.

Common patterns & invariants observed
- ResourcePool + IDisposableReference
  - Pools construct heavy UI objects lazily and return IDisposableReference shaped { object, isStale(): boolean, dispose(): void }.
  - Consumers must call ref.dispose() and check ref.isStale() after async operations before mutating the returned object.
- Progressive / streaming rendering
  - Many parts support incremental rendering and must avoid updating released pooled objects (isStale).
  - Codeblocks and compare models have async codemapper URI flows: UI may render a placeholder and update later when URI arrives.
- Editor/model ephemeral URIs & SHA1
  - Ephemeral URIs use custom schemes (e.g., `Schemas.vscodeChatCodeBlock`) and codemapper URIs are assigned/updated asynchronously.
  - SHA1 of original models is computed (when missing) to support later apply-safe checks.

Porting checklist — prioritized

1) ResourcePool & IDisposableReference — REQUIRED (Effort: S-M)
- Implement exact semantics: get() returns instance; release returns it to pool; returned IDisposableReference must toggle isStale after dispose and call reset() on object before release.
- Add unit tests simulating async setInput/resolution followed by release to detect race conditions.

2) MarkdownRenderer + sanitizer + Katex — HIGH (Effort: S-M)
- Provide MarkdownRenderer copy or adapter with sanitizer options, allowed tags (see [`src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:21`](src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:21)), and MarkedKatex support for math rendering.

3) Editor pool & CodeBlockModelCollection — HIGH (Effort: M)
- Implement EditorPool, CodeBlockPart, and CodeBlockModelCollection for ephemeral models and codemapperUri lifecycle.
- Ensure onDidChangeContentHeight events bubble to chat part and trigger layout remeasure.

4) Text-edit/diff model flow & SHA1 compute — HIGH (Effort: M)
- Implement CodeCompareModelService.createModel flow:
  - createModelReference(original URI), create modified model from snapshot with ephemeral URI, compute originalSha1 (DefaultModelSHA1Computer).
  - Replay edits from chat session requests into modified model and return disposable ref.
  - Preserve short self-acquire to improve reuse during streaming.

5) Attachment widgets, ResourceLabels & hover delegates — MEDIUM (Effort: M)
- Provide attachment widget types and ResourceLabels abstraction supporting icon theming, hover delegates, drag/drop helpers, and context menus.

6) Accessibility & ARIA — MEDIUM (Effort: S)
- Maintain aria labels, keyboard handlers (Enter/Space), alert() announcements for SR users.

7) Tests & QA — MEDIUM (Effort: M)
- Unit tests for model/service logic (ResourcePool, CodeCompareModelService, createModel edge cases).
- Integration/browser tests for widget interactions, hover content, and context menus.

Concrete tests to add (examples)

Unit
- ResourcePool lifecycle: get -> dispose -> pool.release called, isStale toggled.
- CodeCompareModelService.createModel:
  - OriginalSha1 computed when chatTextEdit.state absent.
  - Modified model receives replayed edits from prior chat requests.
- ChatProgressContentPart.shouldShowSpinner behavior across streaming/completion cases.
- ChatAttachmentsContentPart.initAttachedContext selects correct widget types for each variable entry.

Integration
- Markdown rendering produces sanitized DOM; anchor hover titles become managed hovers.
- Code block rendering uses pooled editors; content height changes propagate to the part.
- Text-edit compare opens diff editor with correct original/modified models (uri mapping).

E2E / Smoke
- Simulate a streaming response with codeblocks and progressive updates; verify UI transitions from pills to full editors and codemapperUri assignment updates layout.
- Attach a large image and confirm size-limit rejection message.

Risks & mitigations
- Race conditions on pooled resources (isStale misuse)
  - Mitigation: implement pattern exactly and add timing tests that simulate delayed async resolves.
- Webview/editor surface differences (if porting to alternate host)
  - Mitigation: implement small adapter shims that expose the minimal interfaces used by chat parts.
- Memory with images and ephemeral models
  - Mitigation: enforce size limits, use resizing path and TTL cleanup for temporary files.

Next steps
- Add unit tests for ResourcePool and CodeCompareModelService first (low friction).
- Implement EditorPool + DiffEditorPool shims and a minimal CodeBlockPart for local QA.
- Continue reading remaining content-parts (tool-invocation subparts). Note: one planned file from the earlier batch was not found:
- Missing file: [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInputOutputContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInputOutputContentPart.ts:1)

Cross-references
- [`product_description/features/chat/tests_and_porting_checklist.md:1`](product_description/features/chat/tests_and_porting_checklist.md:1)
- [`product_description/features/chat/references_and_trees.md:1`](product_description/features/chat/references_and_trees.md:1)

End.
