# Chat: Image utilities & content-parts (markdown, progress, text-edit)

Summary
- This document captures responsibilities, call-sites, injected services, lifecycle and porting notes for:
  - image utilities (resize, storage, cleanup),
  - chat status item registry,
  - markdown content part (codeblock rendering, editor pooling, katex handling),
  - progress content parts,
  - text-edit/diff compare model service.

Files read
- [`src/vs/workbench/contrib/chat/browser/imageUtils.ts:1`](src/vs/workbench/contrib/chat/browser/imageUtils.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatStatusItemService.ts:1`](src/vs/workbench/contrib/chat/browser/chatStatusItemService.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1)

Image utils (responsibilities and notes)
- Responsibilities (see [`src/vs/workbench/contrib/chat/browser/imageUtils.ts:1`](src/vs/workbench/contrib/chat/browser/imageUtils.ts:1)):
  - resizeImage(data, mimeType): client-side image resizing using a canvas. Keeps GIFs unchanged and applies OpenAI/token-based sizing rules (scale to max/min axis then final scale to 768px).
  - convertStringToUInt8Array / convertUint8ArrayToString: support conversions for base64/data-URL flows.
  - createFileForMedia(fileService, imagesFolder, data, mimeType): write image bytes into workspace storage with timestamped filename.
  - cleanupOldImages(fileService, logService, imagesFolder): removes files older than 7 days.
- Call-sites:
  - Paste/image providers and drag/drop flows (e.g., [`src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:1`](src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:1), chatInput-related code).
- Porting considerations:
  - Uses DOM canvas, Image and FileReader APIs — port runtime must support these (browser environment or equivalent).
  - Uses platform IFileService for durable storage and joinPath(imagesFolder, filename); ensure workspace storage semantics exist and are secure.
  - Hashing of images uses `crypto.subtle.digest` elsewhere (see paste provider). If target environment lacks Web Crypto, provide a safe fallback.
  - Cleanup policy is time-based (7 days) — surface this in privacy/security docs and consider configurable retention.

Chat status item registry
- Responsibilities (see [`src/vs/workbench/contrib/chat/browser/chatStatusItemService.ts:1`](src/vs/workbench/contrib/chat/browser/chatStatusItemService.ts:1)):
  - Simple singleton service exposing setOrUpdateEntry/deleteEntry/getEntries and onDidChange event.
  - Used by status/dashboard to render contributed status entries dynamically.
- Porting notes:
  - Lightweight — implement equivalent singleton/event emitter and register with DI container.

Markdown content part (chat rendering + codeblocks)
- Responsibilities (see [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1)):
  - Render markdown for chat responses using MarkdownRenderer with sanitized options (allowedChatMarkdownHtmlTags).
  - Detect and render code blocks:
    - Either inline CodeBlockPart (editor) via EditorPool (pooled editors) or CollapsedCodeBlock "pill" when codemapperUri exists and block is collapsed.
    - Manage CodeBlockModelCollection to support streaming updates and codemapperUri metadata for edit/diff flows.
  - Support Katex (math) via MarkedKatexSupport loaded lazily; make Katex blocks horizontally scrollable via DomScrollableElement.
  - Attach ChatMarkdownDecorationsRenderer to scan DOM and inject widgets (anchors, inline actions).
- Important lifecycle & patterns:
  - Editor pooling: EditorPool using ResourcePool; get() returns IDisposableReference with isStale/dispose semantics. Ensure pool.reset() semantics on release.
  - Progressive rendering: renderer.render call returns element; codeBlockRendererSync is used to synchronously allocate editor or pill; asynchronous model updates happen via codeBlockModelCollection.update / updateSync.
  - Layout: part listens to editor.onDidChangeContentHeight and exposes onDidChangeHeight to tree so item heights can be updated.
- Porting risks:
  - Need a markdown renderer with sanitizer config and extension hooks (Katex) and an observable intrinsicContentSize / resize pattern.
  - Editor embedding/pooling requires a host editor component that can be created/destroyed cheaply or pooled safely (ensure decorations/listeners cleared on reuse).
  - CodeBlockModelCollection and ephemeral URI schemes (Schemas.vscodeChatCodeBlock) must be supported to create ephemeral models and track their lifecycle.

Progress content parts
- Responsibilities (see [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1)):
  - Render streaming / progress messages and working progress UI.
  - Decide when to show spinner or hide messages depending on subsequent content (hasSameContent uses followingContent).
  - Render progress steps with accessible alerts for screen reader users (alert()).
  - Support clickable resume for paused working progress.
- Porting notes:
  - Ensure ARIA announcements (alert) and click/keyboard handling semantics are preserved.
  - Need markdown renderer integration (render(progress.content)) and anchor widget rendering (renderFileWidgets).

Text-edit / diff (CodeCompareModelService)
- Responsibilities (see [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1)):
  - Create paired original + modified models for diffing:
    - originalRef = textModelService.createModelReference(chatTextEdit.uri)
    - modifiedRef is created using modelService.createModel from snapshot with a special ephemeral URI (Schemas.vscodeChatCodeBlock + UUID)
  - Compute originalSha1 (DefaultModelSHA1Computer) or use cached state in chatTextEdit.state.
  - Replay earlier edits into modified model by iterating chat session requests and applying pushEditOperations.
  - Return a RefCountedDisposable-like reference that disposes both refs when released.
- Editor UI:
  - DiffEditorPool creates/returns CodeCompareBlockPart instances to render diffs; ChatTextEditContentPart asks codeCompareModelService.createModel and supplies modified/original models to the compare block.
  - DefaultChatTextEditor.apply flow (observed elsewhere) checks SHA1 and prompts user on mismatch before pushing edits to original model.
- Porting risks:
  - Requires text model service capable of:
    - createModelReference(uri) returning resolved model and a proper lifecycle (dispose).
    - createModel from snapshot and create ephemeral URIs reliably.
    - computing SHA1 for text models (or provide equivalent hash).
    - pushEditOperations semantics identical to VS Code's text model.
  - Replay of edits must preserve order and determinism; tests required to ensure edge cases (concurrent edits, partial applies) are handled.
  - RefCounted disposal timeout/short-term acquire pattern: the code self-acquires a reference and releases after 5s for reuse; port must support safe short-lived refs.

Cross-cutting concerns & tests to prioritize
- Tests to validate:
  - resizeImage behavior on various input sizes and GIF passthrough.
  - createFileForMedia writes and cleanupOldImages deletes aged files.
  - EditorPool / DiffEditorPool reuse semantics: ensure reset() clears decorations/listeners and that isStale prevents use-after-release.
  - CodeCompareModelService createModel: originalSha1 calculation, modified model creation from snapshot, replay edits correctness.
  - Markdown rendering: sanitizer config, Katex rendering and scrollable Katex blocks, and decorations injection.
  - Progress parts: show/hide behavior based on subsequent content and working-progress resume click.
- Security/privacy:
  - Images persisted to workspace storage need retention policy (cleanup implemented) and disclosure in porting docs.
  - Markdown sanitizer must match allowedChatMarkdownHtmlTags; remote images should be disabled unless explicitly allowed.

Next steps
- Continue reading remaining chat content parts and actions:
  - Prioritize: chatContentParts/* (remaining), chatAttachmentResolveService, chatDragAndDrop, chatWidget and chatEditor integration files.
- After finishing reading and synthesizing, update MANIFEST and PORTING_CHECKLIST with heavy-lift items: editor pooling, model service, webview surface, paste/document provider API.

References (selected)
- resizeImage & createFileForMedia: [`src/vs/workbench/contrib/chat/browser/imageUtils.ts:19`](src/vs/workbench/contrib/chat/browser/imageUtils.ts:19)
- ChatStatusItemService API: [`src/vs/workbench/contrib/chat/browser/chatStatusItemService.ts:10`](src/vs/workbench/contrib/chat/browser/chatStatusItemService.ts:10)
- Markdown codeblock rendering / pool: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:126`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:126)
- Progress render decision: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:40`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:40)
- CodeCompareModelService flow: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:184`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:184)
