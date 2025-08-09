Quick, Paste, Markdown & Output Rendering
========================================

Summary
-------
This document synthesizes responsibilities, important classes, interactions and porting notes for quick-open chat UI, paste/image handling, markdown rendering/decorations and chat output rendering.

Primary source files examined:
- [`src/vs/workbench/contrib/chat/browser/chatQuick.ts:1`](src/vs/workbench/contrib/chat/browser/chatQuick.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:1`](src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatMarkdownDecorationsRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownDecorationsRenderer.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:1)

Responsibilities (high level)
- Quick-open quick-chat UI: transient quick input, embedded ChatWidget instance, sizing via Sash, temporary model lifecycle. See [`chatQuick.ts:1`](src/vs/workbench/contrib/chat/browser/chatQuick.ts:1).
- Paste providers: image paste provider, copy/paste attachments provider, text paste provider; image hashing/resizing and temporary workspace storage. See [`chatPasteProviders.ts:1`](src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:1).
- Markdown rendering: sanitized markdown rendering tailored for chat, custom hover attachment for anchors and link handling. See [`chatMarkdownRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1).
- Markdown decorations: render inline widgets for agents, slash-commands, file anchors and keybinding hints; replaces special data-href links with interactive widgets. See [`chatMarkdownDecorationsRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownDecorationsRenderer.ts:1).
- Output rendering: pluggable renderer registry for arbitrary MIME types, webview-backed renderers and extension activation gating. See [`chatOutputItemRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:1).

Important classes / APIs / functions
- QuickChatService / QuickChat (`src/vs/workbench/contrib/chat/browser/chatQuick.ts:1`](src/vs/workbench/contrib/chat/browser/chatQuick.ts:1)): IQuickChatService implementation, creates quick input widget, instantiates ChatWidget with compact/renderInputOnTop options, manages transient ChatModel and accept/open-in-chat behavior.
- PasteImageProvider / PasteTextProvider / CopyAttachmentsProvider (`src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:1`](src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:1)): implement DocumentPasteEditProvider, create file storage for pasted images (`createFileForMedia`), compute SHA-256 via `imageToHash`, call `resizeImage`.
- imageToHash(data: Uint8Array) (`src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:152`](src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:152)): uses Web Crypto subtle.digest('SHA-256') producing hex id used as attachment id.
- ChatMarkdownRenderer: extends MarkdownRenderer and applies sanitizer config (allowed tags, disallow remote images) and attaches hover for anchor titles.
- ChatMarkdownDecorationsRenderer: converts parsed request parts into markdown with special data-href schemes (`agentRefUrl`, `decorationRefUrl`), then post-processes DOM to replace anchors with interactive widgets (agent buttons with hover, file anchors, slash commands).
- ChatOutputRendererService: registry of extension-contributed renderers (`chatOutputRenderers` extension point), activates extensions on demand and renders MIME parts inside an IWebview element.

Injected services & runtime dependencies
- QuickInput, Instantiation, Layout, Views services for quick widget parenting and sizing.
- Document paste provider registration via ILanguageFeaturesService.documentPasteEditProvider.
- File storage + environment service for persisted copied images (workspaceStorageHome); fileService for reads/writes.
- Web Crypto API and File/Blob APIs for image hashing and resizing; in non-browser hosts substitute native crypto/fs equivalents.
- Hover, Opener, Command services for link navigation, reveal-in-explorer behavior and managed hovers.
- IWebviewService and extension activation APIs for pluggable output renderers.

UI flows & interactions
- Quick open:
  - createQuickWidget -> instantiate QuickChat -> QuickChat.render creates ChatWidget with compact mode and dynamic layout -> user types and accepts input -> can open in full chat view via openChatView which transfers history and input value.
- Paste:
  - On paste into chat input (scheme vscode-chat-input), providers detect image/text/attachment mime types -> images saved to workspace storage via createFileForMedia -> resized and hashed -> added as attachment to widget. CopyAttachmentsProvider encodes attachments+dynamicVariables into custom MIME so copy/paste across chat inputs preserves attachments.
- Markdown & decorations:
  - ChatRenderer sanitizes markdown and wraps content in <body> to preserve leading comments; post-processing replaces special anchor hrefs with rendered widgets (agent buttons with hover, slash-command buttons, inline anchors).
- Output rendering:
  - When rendering a response that contains an output item with a registered MIME, the ChatOutputRendererService selects a renderer (after activating extension), creates a webview, mounts it in the DOM and delegates renderOutputPart to the renderer.

Lifecycle invariants & patterns
- QuickChat transience: ChatModel created via chatService.startSession and disposed on clear; quick widget must avoid double-render and must clean up Sash and event listeners.
- Paste image lifecycle: temporary file storage directory is cleaned via cleanupOldImages; created Blob/object URLs must be revoked by UI; image hash must be stable for dedup.
- Markdown decoration widgets: post-render DOM manipulation uses DisposableStore to manage widget lifecycle and hover disposables; registration of anchor widgets must be undone on dispose.
- Output renderers: webview intrinsicContentSize observed via observable autorun; RenderedOutputPart provides reinitialize() to restore webview after dismount.

Porting considerations & risks
- Web Crypto and File APIs: imageToHash uses browser crypto.subtle; native ports must provide equivalent SHA-256 and binary handling.
- Workspace storage for pasted images: relies on environmentService.workspaceStorageHome and fileService; for ephemeral or cloud-hosted runtimes choose appropriate storage and cleanup policy.
- Document paste provider integration: VS Code supports document paste provider API; other hosts must provide a hook into paste pipeline to replicate behavior including custom MIME types.
- Webview sandboxing & extension activation: chat output renderers rely on extension activation by event and webview service; port must support dynamic renderer registration and safe webview content rendering.
- Sanitization rules: ChatMarkdownRenderer explicitly restricts tags and disallows remote images — preserve or adapt to host security model.
- Accessibility & keyboard: agent/slash command Buttons and inline widgets include ARIA/hover behaviors and must preserve keyboard focus behavior.

Suggested tests / verification
- QuickChat:
  - Open quick chat, type query, accept input -> results are sent to chatService and model records request.
  - Resize sash and ensure widget.layout updates and disposing widget cleans listeners.
- Paste providers:
  - Paste an image into chat input -> file written under workspaceStorageHome, attachment added with id == imageToHash(buffer).
  - Paste oversized image (>30MB) handled (dialog/error) where applicable.
  - Copy attachments then paste into another chat input -> attachments and dynamic variables restore.
- Markdown & decorations:
  - Render parsed request containing agent & slash commands -> anchor hrefs replaced by interactive widgets with correct click behavior and hover content.
  - Links with title attribute produce managed hover via ChatMarkdownRenderer.attachCustomHover.
- Output rendering:
  - Register a test renderer via IChatOutputRendererService.registerRenderer, ensure renderOutputPart activates extension, mounts webview and calls renderer.renderOutputPart; observe onDidChangeHeight events.

Actionable checklist items
- Implement or adapt:
  - Web Crypto SHA-256 for image hashing.
  - createFileForMedia / workspace image storage & cleanup policy.
  - paste hook to support custom MIME types and document paste semantics.
  - Webview-backed renderer abstraction and extension contribution registry for output renderers.
  - Markdown sanitizer configuration and decoration post-processing (agent/link anchors).
- Add unit/integration tests for paste providers, markdown-decoration replacement, and webview renderer activation.

Next steps
1) Author a contract doc for the paste provider API and image storage expectations so port implementers can supply equivalents.
2) Continue reading remaining chat plumbing files (chatInputPart, chatWidget, chatListRenderer, chatEditor, chatViewPane) and synthesize final widget/input docs.

End.
