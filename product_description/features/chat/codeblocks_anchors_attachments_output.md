Codeblocks, Inline Anchors, Attachment Widgets, Markdown renderer & Output renderers

Summary
- This document synthesizes responsibilities, lifecycles, injected services, integration points and porting risks for:
  - codeblock rendering and compare editors
  - inline file/symbol anchor widgets
  - attachment widgets (images, files, paste, prompt files, notebook outputs, SCM items, tools)
  - chat-focused markdown rendering
  - chat output renderer extension surface (webview-based)

Primary source files
- [`src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1`](src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatInlineAnchorWidget.ts:1`](src/vs/workbench/contrib/chat/browser/chatInlineAnchorWidget.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:1)

Responsibilities & behavior (by area)

1) CodeBlock rendering and diffing
- Code blocks are rendered by `CodeBlockPart` which embeds a read-only `CodeEditorWidget` to show code and exposes:
  - layout/height events via `onDidChangeContentHeight`
  - toolbar (MenuWorkbenchToolBar) with a scoped `IContextKeyService` for per-block menu/context behavior
  - `render(data, width)` sets model via `editor.setModel(textModel)` and applies selection/range and toolbar context
  - `reset()` clears interactive widgets
  - `getContentHeight()` uses either a provided range or editor.getContentHeight()
  - padding and horizontal-scroll detection logic adjusts bottom padding when horizontal scrollbar is present
  - vulnerability list UI: `vulns` + toggle button; aria considerations and keyboard behavior
  - Source: [`CodeBlockPart` implementation](src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:153)

- Compare / text-edit UI:
  - `CodeCompareBlockPart` renders a `DiffEditorWidget` (modified + original), creates a view model from provided `diffData`, and watches original/modified model disposals to safely setModel(null).
  - `CodeCompareModelService.createModel()` (see [`chatTextEditContentPart.ts:184`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:184)) creates:
    - original: `textModelService.createModelReference(uri)`
    - modified: transient model created from original snapshot under a custom scheme (transient codeblock scheme)
    - computes SHA1 of original (DefaultModelSHA1Computer) and replays edits into modified
    - returns a ref-counted pair with delayed self-acquire/release (d.acquire() then setTimeout release) to encourage reuse during streaming
  - `DefaultChatTextEditor` performs apply/discard workflows, with SHA1 checks and fallback prompts for file-changed cases.
  - Sources: [`CodeCompareBlockPart`](src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:528), Diff model creation flow referenced in [`chatContentParts/chatTextEditContentPart.ts:174`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:174).

Implication for port:
- Need robust editor embedding API (code editor + diff editor) with:
  - height/content-size events
  - ability to create transient models and model references
  - deterministic SHA1 or equivalent hashing for "did original change" checks
- ResourcePool semantics (acquire/reset/release) must be preserved so editors can be reused safely.

2) Inline anchor widgets (file / symbol anchors)
- `renderFileWidgets()` scans rendered markdown for anchor elements with empty text and `data-href` attribute and instantiates `InlineAnchorWidget`.
  - Widgets replace anchor contents with an icon + label; attach `data-href` and are registered with `IChatMarkdownAnchorService`.
  - The widget wires:
    - hover (via `IHoverService`)
    - context menu (scoped `IContextKeyService`), using `MenuId.ChatInlineResourceAnchorContext` / `MenuId.ChatInlineSymbolAnchorContext`
    - drag-and-drop (fillEditorsDragData / fillInSymbolsDragData)
    - keyboard actions (copy, open-to-side) registered via `registerAction2` with `chatAttachmentResourceContextKey` precondition
  - Hooking functions like `hookUpSymbolAttachmentDragAndContextMenu` populate provider-specific context keys before showing menu (via temporarily creating a model reference to check capabilities).
  - Source: [`chatInlineAnchorWidget.ts`](src/vs/workbench/contrib/chat/browser/chatInlineAnchorWidget.ts:55)

Implication for port:
- Need label/icon rendering (ResourceLabel), hover & context menu integration, drag data helpers and a scoped context-key system to provide per-widget menus/commands.

3) Attachment widgets & attachment plumbing
- Abstract base `AbstractChatAttachmentWidget`:
  - holds a `ResourceLabel`, exposes `onDidDelete` and `onDidOpen`, supports a clear/remove button and keyboard bindings for deletion
  - `addResourceOpenHandlers()` to open directory vs file and focus semantics
- Concrete widgets:
  - `FileAttachmentWidget` — uses ResourceLabel.setFile, omitted/partial markers, hookUpResourceAttachmentDragAndContextMenu, open handlers
  - `ImageAttachmentWidget` — uses in-memory blob URLs for preview thumbnails, hover image, click-to-open, omitted/partial states and model capability checks (vision support)
  - `PasteAttachmentWidget` — shows pasted content snippet + hover with code block
  - `PromptFileAttachmentWidget`, `PromptTextAttachmentWidget`, `ToolSetOrToolItemAttachmentWidget`, `NotebookCellOutputChatAttachmentWidget`, `ElementChatAttachmentWidget`, `SCMHistoryItemAttachmentWidget` — each have specific open/hover/drag/context behavior
- Utility functions:
  - `createImageElements()` — creates thumbnail/pill and hover image using Blob + URL.createObjectURL
  - `hookUpResourceAttachmentDragAndContextMenu()` + `hookUpSymbolAttachmentDragAndContextMenu()` — set context keys, wire dragstart, and context menu display (calls into `getFlatContextMenuActions`)
  - `chatAttachmentResourceContextKey` (RawContextKey) provides global context key for resource-based actions
  - Source: [`chatAttachmentWidgets.ts`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:58)

Implication for port:
- Need ResourceLabels or equivalent file-label rendering and hover behavior; file/open/opener semantics; drag-and-drop data helpers; ability to produce blob/object-URL previews for images in UI environment (or alternative preview pipeline).

4) Chat-specific Markdown rendering
- `ChatMarkdownRenderer` extends the editor `MarkdownRenderer` and:
  - constrains sanitizer config to `allowedChatMarkdownHtmlTags` and disables remote images by default
  - wraps HTML-capable markdown in `<body>\n\n...` to avoid DOMParser stripping leading comments
  - normalizes plain text nodes into <p> for CSS consistency
  - converts element.title into managed hover via `IHoverService.setupManagedHover`
  - overrides `openMarkdownLink` to reveal directories in explorer when the link points to a directory
  - Source: [`chatMarkdownRenderer.ts`](src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:63)

Implication for port:
- Need a Markdown renderer with sanitizer configurability, hover delegate integration and link-opening hooks. Math/KaTeX support is handled in related code (chatMarkdownContentPart), so markdown renderer should expose extension points for math.

5) Chat output renderer (webview + extensions)
- `ChatOutputRendererService` implements an extension-contributed renderer registry:
  - extension point `chatOutputRenderers` declares { viewType, mimeTypes } and generates activation events `onChatOutputRenderer:<viewType>`
  - `registerRenderer(viewType, renderer, options)` allows in-process registration (e.g., from an extension)
  - `renderOutputPart(mime, data, parent, webviewOptions, token)`:
    - selects renderer by matching mime types (matchesMimeType)
    - creates a webview via `IWebviewService.createWebviewElement({ origin, options: { purpose: WebviewContentPurpose.ChatOutputItem } })`
    - mounts the webview into `parent`, runs renderer.renderOutputPart with the webview
    - autoruns on `webview.intrinsicContentSize` to update parent height
    - returns a `RenderedOutputPart` object exposing `onDidChangeHeight`, `webview`, `dispose()` and `reinitialize()`
  - Source: [`chatOutputItemRenderer.ts`](src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:61)

Implication for port:
- The chat output renderer system depends on:
  - an embeddable webview service with intrinsic content size observable
  - extension activation and activation-by-event semantics
  - secure extension isolation for arbitrary mime renderers
- Ports must provide a comparable extension boundary and webview lifecycle to support external renderers.

Porting risks & required adapters (prioritized)
- Editor embedding & DiffEditor
  - Adapter for `CodeEditorWidget` and `DiffEditorWidget` APIs including layout, content size/height events, getModel/setModel, createViewModel/diff waiting and content change events.
- Model reference & transient models
  - `textModelService.createModelReference(uri)` style API with ref-counted objects exposing `object.textEditorModel` and `uri`.
  - Text model content provider for transient schemes (e.g., `Schemas.vscodeChatCodeBlock`) and ability to create modified snapshot models.
  - Deterministic SHA1 hashing of in-memory model content (DefaultModelSHA1Computer or equivalent).
- ResourcePool & IDisposableReference
  - Pools must support get()/release(), returned refs must implement { object, isStale(), dispose() } and object.reset() before reuse.
- Menu/toolbar/contextkey system
  - Per-widget scoped `IContextKeyService` (createScoped) and MenuWorkbenchToolBar equivalents to present per-block menus with forwarded args.
- ResourceLabels, hover, and tooltips
  - Resource label rendering, hover setup plumbing and tooltip behavior including managed hover for link titles.
- Webview / extension renderer surface
  - Provide webview embedding with intrinsic size observable and an extension activation model by event.
- Image preview & blob handling
  - If running in a non-browser environment (native or server), provide a preview pipeline or fallback rendering for images (thumbnails, placeholder icons).
- Drag & drop / clipboard helpers
  - fillEditorsDragData/fillInSymbolsDragAndContextMenu equivalents for inter-component DnD and multi-format clipboard writes.

Tests to add (recommended)
- CodeBlockPart lifecycle:
  - acquire -> render -> layout -> reset -> release cycles and verify no reuse-after-dispose.
- CodeCompare / diff model:
  - createModel: original+modified creation, edit replay, delayed release semantics (self-acquire), and SHA1-based guard behavior when original changed.
- Inline anchor widgets:
  - rendering anchors -> widget creation, hover & context menu call-sites, dragstart payload, and keyboard shortcuts (copy/open-to-side).
- Attachment widgets:
  - image thumbnail creation using Blob & URL lifecycle, omitted/partial states produce warning UI, clear button keyboard and middle-click deletion behavior.
- ChatMarkdownRenderer:
  - sanitizer config asserts allowed tags, disabled remote image behavior, title->hover conversion and directory link reveal behavior.
- Output renderer:
  - extension activation path, webview instantiation and intrinsic size propagation, reinitializeAfterDismount lifecycle.

Authoring notes / tactical port checklist (next steps)
1. Implement text-model references and a content-provider for transient codeblock URIs (`Schemas.vscodeChatCodeBlock`) — tests: pin/unpin and snapshot creation.
2. Implement ResourcePool and IDisposableReference wrappers used by `EditorPool`/`DiffEditorPool` to avoid reuse-after-dispose.
3. Provide an editor embedding (or shim) with:
   - setModel/getModel, content height events, layout(width,height), padding options and aria labeling.
4. Provide a DiffEditor implementation / shim or replace with a side-by-side diff visualization if full-featured diff editor unavailable.
5. Implement ResourceLabel rendering and hover delegation, plus the context-key system usable by per-widget toolbars.
6. Provide a MarkdownRenderer with sanitizer options and hover-integration (or reuse existing renderer with configured sanitizer).
7. Implement a webview surface that supports intrinsicContentSize observability and a secure extension renderer activation boundary.
8. Port or reimplement drag/clipboard helpers (fillEditorsDragData, fillInSymbolsDragData) for shell integration.

Cross-links (quick)
- Code block rendering and pools: [`src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:153`](src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:153)
- Inline anchors: [`src/vs/workbench/contrib/chat/browser/chatInlineAnchorWidget.ts:55`](src/vs/workbench/contrib/chat/browser/chatInlineAnchorWidget.ts:55)
- Attachments & widgets: [`src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:58`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:58)
- Markdown renderer & sanitizer: [`src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:63`](src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:63)
- Output renderer & webview integration: [`src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:61`](src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:61)

Last updated: 2025-08-09T07:27:08Z
