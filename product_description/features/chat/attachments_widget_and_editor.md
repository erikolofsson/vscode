# Chat: Attachments, Widgets & Editor Integration

Summary
- This document synthesizes responsibilities, call-sites, lifecycle patterns and porting considerations for attachments, attachment widgets, the attachment model, and how chat widgets/editors integrate attachments.

Files read
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatWidget.ts:1`](src/vs/workbench/contrib/chat/browser/chatWidget.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatEditor.ts:1`](src/vs/workbench/contrib/chat/browser/chatEditor.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatDragAndDrop.ts:1`](src/vs/workbench/contrib/chat/browser/chatDragAndDrop.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatQuick.ts:1`](src/vs/workbench/contrib/chat/browser/chatQuick.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatFollowups.ts:1`](src/vs/workbench/contrib/chat/browser/chatFollowups.ts:1)

Responsibilities
- AttachmentResolveService
  - Converts drag/drop, editor inputs, clipboard images and other sources into IChatRequestVariableEntry entries.
  - Validates mime/type, enforces size limits (30MB), reads file bytes, delegates to image resize/hash utilities, and returns structured attachment entries.
  - See [`src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:151`](src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:151).
- ChatAttachmentModel
  - In-memory Map of attachments keyed by id; exposes add/delete/clear/update and emits IChatAttachmentChangeEvent.
  - Supports special handling for prompt-file entries and omitted states.
  - See [`src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:26`](src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:26).
- Attachment Widgets
  - Visual components representing attachments in the UI: FileAttachmentWidget, ImageAttachmentWidget, PasteAttachmentWidget, PromptFileAttachmentWidget, Notebook/SCM widgets, Tool widgets, etc.
  - Manage resource labels, hover content, keyboard/mouse interactions, clear/remove controls, and drag/context menu wiring.
  - See [`src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:58`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:58).
- ChatWidget / ChatEditor integration
  - ChatWidget composes inputPart, tree renderer, attachmentModel and ensures attachments are incorporated into send flows, undo/redo, and working-set behavior.
  - ChatEditor hosts ChatWidget inside EditorPane, sets memento/viewState and handles session-based locking to coding agents.
  - See [`src/vs/workbench/contrib/chat/browser/chatWidget.ts:123`](src/vs/workbench/contrib/chat/browser/chatWidget.ts:123) and [`src/vs/workbench/contrib/chat/browser/chatEditor.ts:36`](src/vs/workbench/contrib/chat/browser/chatEditor.ts:36).

Key behaviors and call-sites
- Drag & drop and context menus
  - hookUpResourceAttachmentDragAndContextMenu and hookUpSymbolAttachmentDragAndContextMenu set scoped context keys, call fillEditorsDragData/fillInSymbolsDragData for drag payload, and register contextual menus via IMenuService.
  - Drag overlay, drop-type estimation, HTML URL/file handling and in-place URL insertion are handled by [`chatDragAndDrop.ts:1`](src/vs/workbench/contrib/chat/browser/chatDragAndDrop.ts:1). Important functions: resolveAttachmentsFromDragEvent, resolveHTMLAttachContext, downloadImageAsUint8Array.
  - See context-menu wiring in [`chatAttachmentWidgets.ts:825`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:825).
- Resolve & attachment creation
  - `ChatAttachmentResolveService` implements resolveEditorAttachContext / resolveResourceAttachContext / resolveImageAttachContext and higher-level helpers to create IChatRequestVariableEntry objects. It enforces size caps (30MB), handles GIF partial-omission semantics, computes stable ids (imageToHash) and delegates to resizeImage before returning entries. See [`chatAttachmentResolveService.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1).
- Image & paste flow
  - Paste/drag providers create workspace-stored files via createFileForMedia, then call resizeImage and imageToHash to generate stable ids before adding to attachmentModel. See paste provider references in [`chatPasteProviders.ts:1`](src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:1) and image utils in [`imageUtils.ts:1`](src/vs/workbench/contrib/chat/browser/imageUtils.ts:1).
- References list & per-item toolbars
  - `ChatCollapsibleListContentPart` (references list) uses a `CollapsibleListPool` (ResourcePool) to avoid re-allocating heavy lists and attaches per-item `MenuWorkbenchToolBar` instances using a scoped IContextKeyService so per-row menus/actions resolve correctly. See [`chatContentParts/chatReferencesContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:1).
- Attachment lifecycle
  - ChatAttachmentModel.updateContext performs atomic added/updated/deleted diffs and fires a single onDidChange event for consumers to react to.
  - Attachment widgets call attachClearButton() and emit onDidDelete; inputPart listens to attachmentModel.onDidChange to refresh parsed input and layout.
- Quick chat & followups integration
  - QuickChat/QuickChatService creates an ephemeral ChatWidget inside the quick input surface (quick pick) and can replay prior request responses into a full Chat view. It preserves scroll and supports sash resizing; inputs can be transferred/opened into the main chat view via showChatView. See [`chatQuick.ts:1`](src/vs/workbench/contrib/chat/browser/chatQuick.ts:1).
  - Followup buttons are rendered by `ChatFollowups` which composes MarkdownString labels and derives tooltip prefixes via formatChatQuestion; rendering depends on a default agent being available for the target location. See [`chatFollowups.ts:1`](src/vs/workbench/contrib/chat/browser/chatFollowups.ts:1).

UI & accessibility notes
- Widgets use ResourceLabels for file-like UI (supports icons and hover titles); images create object URLs and revoke on load (see image building in [`chatAttachmentWidgets.ts:334`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:334)).
- Accessible labels (ariaLabel) are set for omitted/partial/full states and file attachments include contextual text (line ranges).
- Keyboard support: clear via Backspace/Delete, open via Enter/Space, middle-click removal.

Lifecycle & pooling considerations
- Attachment widgets are ephemeral per render; they must be disposed when removed. AttachmentModel is the canonical source of truth.
- ChatWidget pools heavy editors/codeblocks separately (EditorPool / DiffEditorPool). Attachment DOM widgets are lightweight but still require disposal to avoid leaks.
- Scoped context keys per widget are used extensively (resource binding) — ensure context key service semantics are available when porting.

Porting risks and required platform features
- Required services/APIs:
  - IFileService: stat/readFile/writeFile/createFolder/del/resolve
  - ITextModelService: createModelReference and model lifecycle
  - IHoverService, IMenuService, IContextMenuService, IContextKeyService
  - IInstantiationService / DI container, ResourceLabels, ILabelService, IOpenerService
- Host runtime expectations:
  - DOM APIs: Blob, URL.createObjectURL, FileReader, Canvas (for image resizing in imageUtils).
  - Drag-and-drop dataTransfer manipulation, including custom drag images and editor drag helpers.
  - Web Crypto (crypto.subtle.digest) used elsewhere for hashing — provide fallback if absent.
- Security/privacy:
  - Images written to workspace storage require retention/cleanup policy (cleanupOldImages) and should be disclosed in privacy documentation.
  - OmittedState semantics must be preserved to avoid sending partial/audio/large content unintentionally.
- UX surface gaps to implement:
  - ResourceLabels with icon/theme support.
  - Hover tooltips that can render Markdown and trap focus.
  - Context menu contributions (MenuId keys) and activation hooks for extension-driven actions.

Tests to prioritize
- Unit
  - ChatAttachmentResolveService.resolveImageEditorAttachContext: mime detection, size limit, proper error when >30MB.
  - ChatAttachmentModel.updateContext: correct added/updated/deleted events and dedup logic.
- Integration
  - Paste flow: image paste goes through createFileForMedia -> resizeImage -> attachmentModel.addContext -> ImageAttachmentWidget displays.
  - Drag from explorer to chat input: drag payload created and attachment added; context menu actions open/reveal resource.
- E2E / Visual
  - Hover images load and object URLs are revoked (no leaks).
  - Accessibility: ariaLabels and alert flows for progress/omitted states.

Implementation checklist (port)
- Implement or shim:
  - IFileService and workspace storage semantics (createFolder/writeFile/del/resolve).
  - ITextModelService and text model references required by resolveResourceAttachContext and attachment workflows.
  - ResourceLabels/ILabelService for consistent file UI.
  - IHoverService and managed hover with Markdown support.
  - Drag-and-drop helpers: fillEditorsDragData / fillInSymbolsDragData equivalents.
  - Web Crypto or deterministic fallback for image hashing.
  - DOM image/canvas APIs for resizeImage or server-side resizing alternative.
- Preserve policies:
  - Retention/cleanup (7 days by default) for workspace-saved images.
  - Size limits and GIF special-case behavior.

Cross-references
- Paste providers and input call into attachment resolve paths (see [`src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:59`](src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:59) and input wiring at [`src/vs/workbench/contrib/chat/browser/chatInputPart.ts:101`](src/vs/workbench/contrib/chat/browser/chatInputPart.ts:101)).
- ChatWidget exposes attachmentModel for other subsystems (e.g., telemetry, editing session logic) via `attachmentModel` getter (see [`src/vs/workbench/contrib/chat/browser/chatWidget.ts:531`](src/vs/workbench/contrib/chat/browser/chatWidget.ts:531)).

Next steps
- Continue reading remaining chatContentParts and action wiring (chatContentParts/*, actions/chatContextActions.ts) and synthesize into feature docs.
- Produce consolidated PORTING_CHECKLIST with rough effort estimates and top-5 mitigation plans for heavy-lift items (editor pooling, model service, webview surface, paste provider API, file storage).
- Map tests to CI and identify minimal service shims required to validate critical flows (image paste, attach, send).

Selected references
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:151`](src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:151)
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:245`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:245)
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:26`](src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:26)
- [`src/vs/workbench/contrib/chat/browser/chatWidget.ts:123`](src/vs/workbench/contrib/chat/browser/chatWidget.ts:123)
- [`src/vs/workbench/contrib/chat/browser/chatEditor.ts:36`](src/vs/workbench/contrib/chat/browser/chatEditor.ts:36)
