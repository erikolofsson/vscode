Attachments & Markdown — responsibilities and port notes

Summary:
This document summarizes the attachments subsystem and chat markdown rendering, the widgets that render attachments, how codeblocks are handled inside markdown, and porting considerations.

Responsibilities:
- Render and manage attachments attached to a chat input (files, images, pastes, prompt files, notebook outputs, SCM history items, tools/toolsets).
- Convert drag-and-drop, clipboard paste and editor context into IChatRequestVariableEntry instances consumed by the chat model.
- Render sanitized markdown for responses, attach hover behavior for links/titles, and coordinate codeblock rendering (full editors or collapsed pills).

Key files:
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:1`](src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1)

Attachment types and widgets:
- File attachments: rendered by FileAttachmentWidget; uses ResourceLabels for icon + name and supports range selection open and omitted-state warnings.
- Image attachments: ImageAttachmentWidget shows a pill + preview hover; supports pasted images and remote images via the extractor.
- Paste attachments: PasteAttachmentWidget shows pasted snippet metadata and hover content with a code preview.
- Prompt files & prompt text: PromptFileAttachmentWidget and PromptTextAttachmentWidget render prompt attachments and link into prompt parsing workflow.
- Tool / ToolSet attachments: Rendered as simple labeled buttons with hover descriptions.
- Notebook outputs: NotebookCellOutputChatAttachmentWidget supports images, error objects and generic outputs.

Attachment model & lifecycle:
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1) maintains a Map<id,IChatRequestVariableEntry>, emits onDidChange with deleted/added/updated arrays.
- APIs: addFile(uri, range), addFolder(uri), addContext(...), delete(...), clear(), clearAndSetContext(...).
- Images are special-cased via asImageVariableEntry which may call into the web content extractor or the resolve service.

Drag & drop, context menu & DnD:
- Helpers wire dragstart to populate editor drag data and call setDragImage. See hookUpResourceAttachmentDragAndContextMenu and hookUpSymbolAttachmentDragAndContextMenu for context-key wiring and dynamic menu population (provider context keys depend on language features).

Markdown rendering & codeblocks:
- [`src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1) wraps the MarkdownRenderer with a sanitizer config (allowedChatMarkdownHtmlTags) and disables remote images by default. It also normalizes text nodes into paragraphs and attaches hover behavior for anchor titles.
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1) slices markdown and:
  - Renders code blocks either as an embedded editor (`CodeBlockPart`) or as a collapsed pill (`CollapsedCodeBlock`) depending on codemapperUri / edit semantics.
  - Uses `CodeBlockModelCollection` to manage streaming codeblock models and `EditorPool` to get pooled editors.
  - Supports inline extensions (vscode-extensions blocks), math (Katex) and layout adjustments (scrollable Katex containers).

Text-edit / diff integration:
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1) renders text-edit groups as either summaries or full diffs.
- It uses a `DiffEditorPool` and an `ICodeCompareModelService` implementation that:
  - Creates original model ref via textModelService.createModelReference(uri).
  - Creates modified model from snapshot under a `vscodeChatCodeBlock` URI generated with a UUID.
  - Computes originalSha1 via DefaultModelSHA1Computer and replays previous edits into the modified model.
  - Returns a reference that must be disposed to release both models.

Security, privacy & storage:
- Image read size safeguard (30 MB) in resolve service; pasted images are resized via `resizeImage`.
- Paste providers compute stable IDs via hashing (`imageToHash`) and write images to workspace storage (target path must be chosen carefully when porting).
- Markdown sanitization restricts allowed tags/attributes and disables remote images by default; port should preserve this.

Accessibility & hover:
- Attachment widgets provide `ariaLabel` and keyboard handlers (Enter/Space + key navigation). Managed hovers are attached for labels and previews using the platform's hover service.
- Markdown renderer attaches managed hover for anchors whose title property was used as tooltip content.

Porting considerations / risks:
1) UI primitives: ResourceLabels, hover, action toolbars, context menu population and DnD rely on host workbench APIs. Port must provide equivalent abstractions.
2) Binary handling: reading remote images, resizing, hashing, and temporary storage require a secure filesystem and an extractor service (or adapter).
3) Ephemeral URI schemes & text model lifecycle: `vscodeChatCodeBlock` URIs and model references are used to create modified models and must be supported or replaced by a compatible strategy.
4) Sanitization: ensure the target platform's markdown sanitizer enforces the allowed tag/attribute lists and disallows remote image loading by default.
5) Language & symbol context keys: symbol-attachment context menus rely on language feature registries and text model presence checks; replicate provider-availability checks.

Tests & validation:
- Unit tests: ChatAttachmentModel update flows (add/update/delete), image resolution paths and omitted states.
- Integration tests: DnD/dragstart data, context menu actions, and editor open handlers attached to attachments.
- Visual tests: image pill, hover preview rendering, collapsed codeblock -> expand flow, diff rendering for text-edit groups.

Implementation notes / suggested steps for port:
- Implement or shim `ChatAttachmentModel` with the same public methods and change event semantics.
- Provide a minimal ResourceLabel component (icon + label + hover) and hover delegation.
- Implement attachment resolve helpers (file vs http images) and an image resizing/hash helper.
- Provide a markdown wrapper that enforces same sanitizer options as in [`src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1).
- Implement EditorPool / DiffEditorPool and a model creation strategy for compare diffs (or expose a simpler apply path if diff editors not available).

Cross-links:
- Widget & input doc: [`product_description/features/chat/widget_and_input.md:1`](product_description/features/chat/widget_and_input.md:1)
- Codeblocks doc: [`product_description/features/chat/codeblocks.md:1`](product_description/features/chat/codeblocks.md:1)

End of doc.
