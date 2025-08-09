# Chat — Attachments & Tools

Purpose
- Handle attachments and tool selections used as implicit context for requests: files, images, prompt files, pasted code, notebook outputs, SCM history, symbols, and tool/toolsets.

Responsibilities
- Centralize attachment lifecycle: add/remove, resolve content, omit/partial states.
- Render attachment chips in input and message-level attachment lists.
- Provide attachment widgets with open/delete/drag/drop/context-menu handlers.
- Integrate tool selection (ToolSet/Tool) and present hover/tooltips for tools.

Key implementation files
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1)
- Attachment content parts: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1)
- Reference list & context menu: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:1)
- Attachment resolve service: [`src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1)

Runtime services & integrations
- IFileService, IOpenerService, IHoverService, IContextMenuService for open/hover/context actions.
- ISharedWebContentExtractorService for extracting images from web URLs.
- ILanguageModelToolsService to map tool IDs to ToolSets/Tools and provide metadata.

UI patterns & behaviors
- Attachment chips: focusable, keyboard-accessible chips with clear/remove buttons.
- Image attachments render thumbnails with hover preview (object URLs).
- File attachments use ResourceLabels to show file icons and paths.
- Notebook outputs and paste attachments render specialized content (images, code previews).
- Drag-and-drop support to editor or open in side bar; context menus driven by MenuId.ChatAttachmentsContext.

Data model & omitted state
- Attachments may be OmittedState.Full/Partial to indicate privacy/truncation.
- ChatAttachmentModel stores attachments keyed by id and emits IChatAttachmentChangeEvent for UI updates.

Porting checklist (attachments)
- Provide a small resource-label component to render file icons, paths and support hovers.
- Implement blob/object-url image preview with revoke-on-load semantics.
- Implement drag/drop helpers mapping to target platform editor/open behaviors.
- Implement extraction of images from remote URLs (or document how that will be handled).
- Implement context menu integration with per-resource actions and menu filtering.
- Recreate ILanguageModelToolsService or adapt tool metadata to target runtime.

Security & privacy considerations
- Ensure remote image fetching is controlled; avoid auto-loading remote images in renderer.
- Respect omitted/partial attachment semantics; avoid leaking full content.

Testing & QA
- Unit tests for ChatAttachmentModel add/delete/update events and omitted state behavior.
- UI tests for attachment chip rendering, keyboard interactions, drag/start behavior and context menus.
- Integration tests to validate attachments included in sendRequest payloads and that resolution/payload size limits are enforced.

Cross-links
- Chat input: [`product_description/features/chat/input.md:1`](product_description/features/chat/input.md:1)
- Chat widget: [`product_description/features/chat/widget.md:1`](product_description/features/chat/widget.md:1)
- Chat overview: [`product_description/features/chat/overview.md:1`](product_description/features/chat/overview.md:1)
