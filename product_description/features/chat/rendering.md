# Chat — Rendering & List (progressive rendering, markdown, codeblocks)

This document summarizes the Chat UI rendering architecture: virtualized list, dynamic heights, progressive streaming render, markdown decorations, and editor pooling. It captures responsibilities, important flows, and porting considerations.

Related source files
- Primary renderer and delegates:
  - [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1)
- Markdown & decorations:
  - [`src/vs/workbench/contrib/chat/browser/chatMarkdownDecorationsRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownDecorationsRenderer.ts:1)
- Markdown rendering + codeblock parts referenced:
  - [`src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1)
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1)
- Code block & editor pooling:
  - [`src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1`](src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1)
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1)

High-level responsibilities
- Virtualized list rendering of chat items with dynamic heights (WorkbenchList / WorkbenchObjectTree).
- Delegation of message rendering into composable content parts (markdown, references, codeblocks, diffs, followups).
- Progressive streaming render of responses: word-slicing, rate heuristics, and debounced updates.
- Markdown decorations transform placeholder links into interactive widgets (agent buttons, file anchors, slash commands).
- Editor pooling for embedded editors (CodeEditorWidget / DiffEditorWidget) to avoid high creation cost.

Key implementation notes
- ChatListItemRenderer
  - Implements ITreeRenderer; creates templates containing header, avatar, value, footer toolbars.
  - Maintains pools: EditorPool, DiffEditorPool, TreePool, CollapsibleListPool.
  - Tracks code blocks by response id and by editor URI to support open-in-editor flows.
  - Progressive rendering:
    - getProgressiveRenderRate() computes words/s rate.
    - getNextProgressiveRenderContent() slices Markdown into N words using getNWords().
    - doNextProgressiveRender() diffs desired content vs renderedParts and applies only changed content.
  - Diffing strategy: content parts are compared via hasSameContent to minimize DOM churn.
  - Height management:
    - Template row container offsetHeight used to set element.currentRenderedHeight.
    - Emits onDidChangeItemHeight to notify list to update virtualization.
  - See [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1).

- Markdown Decorations
  - ChatMarkdownDecorationsRenderer converts special inline constructs into anchor URLs (agentRefUrl, decorationRefUrl).
  - walkTreeAndAnnotateReferenceLinks() replaces anchors with interactive widgets:
    - Agent widgets (clickable buttons that send sample requests)
    - Slash command widgets (invoke agent slash commands)
    - File widgets / Inline anchors (InlineAnchorWidget)
  - Also injects keybinding hints for command: links by consulting IKeybindingService.
  - See [`src/vs/workbench/contrib/chat/browser/chatMarkdownDecorationsRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownDecorationsRenderer.ts:1).

Editor pooling and codeblock lifecycle
- Heavy editors (code and diff) are created on-demand and reused via ResourcePool pattern.
- CodeBlockModelCollection manages codemapper URIs for streaming codeblock updates.
- When a markdown part contains codeblocks, the content part yields codeblocks[] with uriPromise; renderer registers these and maps uri→codeblock info.
- Opening a codeblock in a full editor uses a chat-specific scheme (vscodeChatCodeBlock) and handlers that reveal/focus the matching embedded editor if already present.
- See the CodeBlockPart and the pools referenced in [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1) and [`src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1`](src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1).

Progressive rendering semantics & heuristics
- Word-rate estimation:
  - If element.isComplete or paused, higher implied minimum rate used.
  - Rate clamped between configurable min/max and adjusted via element.contentUpdateTimings?.impliedWordLoadRate.
- Buffering:
  - element.renderData stores lastRenderTime and renderedWordCount to avoid re-announcing same content.
- Inclusion rules:
  - Always include "references" part first to avoid re-diffing after references arrive.
  - When taking partial Markdown chunks, ensure non-markdown trailing parts are included to avoid UI jumps.

Performance considerations
- Pools reduce cost but require careful lifecycle to avoid leaking editors or models.
- Diffing content parts is critical to reduce DOM thrash; hasSameContent implementations must be efficient.
- Height recalculation is expensive; the renderer delays firing height update events with requestAnimationFrame to coalesce changes.

Accessibility & Decorations
- Decorators translate agent references and slash commands into keyboard-focusable buttons with hover content (ChatAgentHover).
- Inline file anchors are turned into InlineAnchorWidget which supports keyboard and context-menu interactions.
- The chat accessibility provider composes concise aria labels from rendered markdown/token analysis (tables/codeblocks counts) — see [`product_description/features/chat/accessibility.md:1`](product_description/features/chat/accessibility.md:1).

Porting checklist (rendering)
- [ ] Provide a virtualized list control that supports dynamic heights and explicit per-item height updates.
- [ ] Implement a content-part abstraction so each logical piece (markdown, references, tool-invocations, codeblocks) renders independently and exposes height-change events.
- [ ] Implement a progressive renderer:
  - Word-sliced markdown trimming function equivalent to getNWords().
  - Rate controller for words/s and renderData bookkeeping.
- [ ] Implement editor pooling/resource pool for embedded code editors and diff editors and a mechanism to map codeblock URIs to pooled editors.
- [ ] Implement markdown-decoration replacement that can inject interactive widgets and keybinding hints.
- [ ] Expose a mechanism for parts to report height changes and for the list to update virtualization.
- [ ] Add telemetry and defensive logging around replacement/DOM operations to surface hierarchy errors quickly.

Testing matrix
- Unit tests:
  - hasSameContent semantics per content part.
  - getNWords and progressive slicing edge cases.
  - Editor pool acquire/release with concurrent requests.
- Integration tests:
  - Streaming response gets progressively rendered in the UI; height updates propagated to list and virtualization remains consistent.
  - Agent/slash widgets render and respond to clicks and keybinding-invoked commands.
- Visual tests:
  - Snapshot tests of rendered parts (markdown with codeblocks, references, file widgets) to detect regressions.

Open risks & notes
- Rendering race conditions when streaming arrives concurrently with pool editor creation — prefer locking or queuing model updates.
- Complex content diffs may be expensive; consider batching diffs when many small updates arrive quickly.
- Webview-based renderers (extensions) may introduce cross-context performance/latency — gate them and provide timeouts.
