# Tests & Porting Checklist — Chat subsystem

Summary:
- This document maps tests to chat features and provides a prioritized porting checklist focused on attachments, markdown rendering, and output rendering (based on recently read implementation files).

Related implementation files:
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:1)

Responsibilities & behaviours to test:
- Attachment discovery & classification (file vs image vs directory vs notebook output).
- Image handling: resize, hashing id, omitted states (Partial/Full), MIME checks and size limit.
- Attachment model: add/delete/clear/update events and ID semantics.
- Attachment widgets: ARIA labels, open handlers, drag/drop, context menus, clear button behavior.
- Prompt file detection for language-specific prompt/instruction files.
- Markdown rendering: sanitizer config, allowed tags, remote image blocking and custom hover behavior.
- Output rendering: dynamic renderer discovery via extension contributions, webview lifecycle and height updates.

Test mapping (recommended tests)

Unit tests (fast, isolated):
- ChatAttachmentModel
  - addFile with image vs non-image paths → correct variable entry created (use stubbed fileService & webContentExtractor) (see [`src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:142`](src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:142))
  - addContext / delete / clearAndSetContext → events (deleted/added/updated) emitted correctly
  - asImageVariableEntry resolves http(s) images via webContentExtractor and delegates to resolve service
- ChatAttachmentResolveService
  - resolveImageEditorAttachContext: rejects unsupported extensions, rejects >30MB, returns omittedState for GIFs
  - resolveResourceAttachContext: prompt file detection via getPromptsTypeForLanguageId
  - resolveSymbolsAttachContext, resolveMarkerAttachContext, resolveNotebookOutputAttachContext behavior
- ChatMarkdownRenderer
  - sanitizer options applied (allowedChatMarkdownHtmlTags), remote images blocked, title-anchored hover setup
  - openMarkdownLink opens directories via REVEAL_IN_EXPLORER command when applicable
- ChatOutputRendererService (unit)
  - registerRenderer / getRenderer logic (contribution activation flow mocked)
  - renderOutputPart creates webview with correct origin, intrinsic size autorun influences parent height

Integration tests (requires browser/webview stubbing):
- Attachment widget interactions
  - clicking / keyboard Enter/Space opens resource (openerService mock) and focuses widget
  - middle-click triggers delete when supported and no range
  - clear button removes attachment and fires model events
- ImageAttachmentWidget
  - blob -> objectURL rendering, hover image load success & error fallback
- PasteAttachmentWidget hover content contains pasted code snippet
- NotebookCellOutputChatAttachmentWidget resolves cell output and renders image/error
- Context menu / dragstart uses fillEditorsDragData and sets proper drag image

End-to-end / smoke:
- Register a simple chat output renderer extension (mock) and verify chat UI mounts a webview and shows rendered content and height updates.
- Attach a large (>30MB) image via editor attach flow and assert an error dialog is raised.

Prioritized Porting Checklist (top to bottom)
1) Core services & DI wiring — HIGH (Effort: S)
   - Ensure instantiation/DI equivalent for IChatAttachmentResolveService, ChatAttachmentModel, ChatOutputRendererService and MarkdownRenderer wrapper.
   - Rationale: fundamental to all chat features; missing DI registration breaks behavior.

2) File & image I/O — HIGH (Effort: M)
   - Implement fileService.read/stat equivalents, webContentExtractor, and correct blob/VSBuffer handling.
   - Validate image size limit (30MB) and supported image mime check (see [`src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:151`](src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:151)).

3) Attachment storage & IDs — HIGH (Effort: M)
   - imageToHash and resizeImage equivalents, stable ID computation (SHA-256) for pasted images.
   - Persist temporary files for attachments and implement cleanup TTL semantics.

4) Webview & output renderers — HIGH (Effort: M-L)
   - Provide webview API with intrinsicContentSize observable, reinitializeAfterDismount, origin management and extension activation hooks used by ChatOutputRendererService (see [`src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:100`](src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:100)).

5) Markdown rendering & sanitizer — MEDIUM (Effort: S-M)
   - Port MarkdownRenderer with sanitizerConfig and custom hover attachment; allow product.urlProtocol augmentation.

6) UI behaviors & accessibility — MEDIUM (Effort: M)
   - Keyboard handlers, ARIA labels, hover delegates, and image fallback behavior from Attachment widgets.

7) Context menus & drag/drop — MEDIUM (Effort: S-M)
   - Recreate contextKey wiring and addBasicContextMenu utility, ensure fillEditorsDragData / dnd behavior.

8) Tests — MEDIUM (Effort: M)
   - Implement unit tests for model/service logic; integration/browser tests for widgets and webview flows.

Risks & Mitigations
- Risk: Webview platform differences (message passing, intrinsic sizing, lifecycle) cause renderer breakage.
  Mitigation: Create an adapter that exposes the minimal IWebview surface used by chatOutputRenderer (mountTo, intrinsicContentSize observable, webview.reinitializeAfterDismount). Add unit tests around reinitialize and height updates.

- Risk: Image handling & temporary storage security.
  Mitigation: Ensure temp file location has appropriate permissions; sanitize file names; enforce TTL cleanup job and hashed IDs.

- Risk: Pooling / isStale semantics for editors and parts (reuse vs. disposal) — leads to use-after-dispose bugs.
  Mitigation: Port ResourcePool and IDisposableReference patterns exactly; add unit tests that simulate reuse and mark isStale after dispose.

Next actionable steps
- Implement unit tests for ChatAttachmentModel and ChatAttachmentResolveService first (low friction).
- Build small webview shim and test ChatOutputRendererService.renderOutputPart with a test renderer.
- Add integration tests for Attachment widgets using headless DOM environment or Puppeteer.

References
- Implementation files referenced above.
- Existing docs: [`product_description/features/chat/attachments_and_markdown.md:1`](product_description/features/chat/attachments_and_markdown.md:1)
- Current manifest: [`product_description/MANIFEST.md:1`](product_description/MANIFEST.md:1)
