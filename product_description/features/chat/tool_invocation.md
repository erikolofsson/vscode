# Tool Invocation & Output (Chat)

Purpose: describe how the chat subsystem invokes external "tools" (language model tools, terminals, installers), renders their progress and outputs, how webview-based output renderers are integrated, and porting considerations.

Files & primary constructs reviewed
- Files:
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1)
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1)
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1)
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:1)
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:1)

- Important language declarations (clickable):
  - [`class ChatToolInvocationPart()`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:29)
  - [`class ChatToolOutputSubPart()`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:30)
  - [`class ChatToolProgressSubPart()`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:18)
  - [`class ChatResultListSubPart()`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:16)
  - [`class BaseChatToolInvocationSubPart()`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:11)

Responsibilities and runtime behavior
- ChatToolInvocationPart
  - Orchestrates which UI sub-part to render for a tool invocation based on the toolInvocation shape (live object vs serialized), its kind, confirmation messages, and resultDetails.
  - Rerenders itself (mutating model) when the underlying toolInvocation resolves (e.g., isCompletePromise) or when sub-part requests rerender.
  - Key decision points are in [`createToolInvocationSubPart()`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:82): it routes to extension-install confirmation, terminal confirmation, result lists, I/O pairs, or generic progress.
  - Source: [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1)

- Tool progress rendering
  - `ChatToolProgressSubPart` renders a progress message or a specialized past-tense message when complete; it uses `ChatProgressContentPart` internally to get spinner/ARIA semantics.
  - Source: [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1)

- Tool result lists
  - `ChatResultListSubPart` wraps a list of URIs/Locations into a `ChatCollapsibleListContentPart` to present a compact list of results.
  - Source: [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:1)

- Tool output (webview / binary outputs)
  - `ChatToolOutputSubPart` is responsible for rendering tool outputs which may be binary data or structured content.
  - Important behavior:
    - It normalizes live vs serialized `toolInvocation` details into a single `IToolResultOutputDetails` shape (handles base64-decoded serialized output).
    - Creates a small placeholder progress UI (`ChatCustomProgressPart`) while the output renderer is initialized.
    - Uses the contributed output renderer service to render into a container:
      - Call site: `this.chatOutputItemRendererService.renderOutputPart(...)`
      - See invocation: [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:111`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:111)
    - Keeps a small in-memory cache of per-widget per-toolCallId OutputState (webviewOrigin + last height) so that re-renders preserve height and can reinitialize webviews reliably. Cache lives in [`ChatToolOutputSubPart._cachedStates`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:33).
    - Registers listeners so that wheel events inside the webview delegate scroll to the containing chat widget (delegateScrollFromMouseWheelEvent).
    - Reinitializes the webview when the containing widget becomes visible again: `renderedItem.reinitialize()` on widget onDidShow.
    - Source: [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1)

Common patterns & interactions
- Live vs serialized invocations
  - `toolInvocation` can be a live object (`kind === 'toolInvocation'`) or a serialized snapshot. Parts handle both shapes and decode base64 for serialized output (see `decodeBase64` usage in the output part).
- Sub-part polymorphism
  - All tool UI parts implement `BaseChatToolInvocationSubPart` so that `ChatToolInvocationPart` can uniformly host them and listen for onNeedsRerender/onDidChangeHeight events.
  - See base class `BaseChatToolInvocationSubPart` and its isCompletePromise wiring to trigger rerender on completion: [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:1)
- Webview renderer integration
  - Rendering tool output delegates to `IChatOutputRendererService`. The renderedItem is disposable and exposes:
    - onDidChangeHeight(newHeight) — used to update cached height and trigger layout.
    - webview.onDidWheel — used to feed wheel events back into chat widget scrolling.
  - Reuse & caching of webview/rendered state across re-renders reduces jank and preserves scroll/height.

Porting considerations & required platform primitives
- Webview surface & security origin handling (high)
  - Chat tool outputs rely on a hosted webview-like surface and a stable origin token per rendered item (`webviewOrigin: generateUuid()`), used for secure embedding and isolation.
  - The target platform must provide a webview host with:
    - create/destroy/reinitialize APIs,
    - onDidChangeHeight event,
    - onDidWheel forwarding,
    - a way to pass an "origin" or isolation token to the renderer.
  - See `renderOutputPart(...)` usage: [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:111`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:111)

- Renderers & extension activation (medium)
  - The upstream renderer service will activate extensions and provide a per-mime renderer (e.g., images, html, notebook-like outputs). The port must support pluggable output renderers with lifecycle callbacks and size reporting.

- Caching & reinitialization (medium)
  - The cached OutputState pattern preserves webviewOrigin + height in memory keyed by Widget ViewModel and toolCallId. Port must replicate caching semantics or choose an equivalent storage (weak map keyed by in-memory widget object).

- Wheel/scroll delegation (medium)
  - Webview content wheel events are captured and must be translated into host scroll handling to avoid nested-scroll UX issues. Implement delegateScrollFromMouseWheelEvent equivalent in your chat container to accept synthetic events from the webview.

- Serialized artifact handling (low)
  - Support for serialized tool outputs (base64 data) is needed if tool outputs are saved/transported in serialized chat transcripts.

Risk matrix & mitigations
- Missing webview capability (High): If the porting target lacks a secure webview with height reporting, tool-output experience will degrade.
  - Mitigation: Provide a limited HTML renderer with size reporting and fall back to download/view-as-file for binary outputs.
- Reinitialization complexity (Medium): Webviews must reinitialize when DOM is reattached; forgetting this will show blank outputs after virtualization or view changes.
  - Mitigation: Ensure rendered items expose reinitialize() and wire host onShow events similarly to upstream code.
- Memory growth from cached states (Low): WeakMap usage avoids leaks, but equivalent behavior must be preserved.
  - Mitigation: Use weak-keyed caches or attach lifecycle hooks to clear cache on widget disposal.

Tests to add
- Unit
  - Assert that `ChatToolInvocationPart.createToolInvocationSubPart()` routes to the correct sub-part for multiple `toolInvocation` shapes (extensions, terminal, input/output, progress).
  - Verify `ChatToolOutputSubPart.createOutputPart()` decodes serialized payloads and calls `renderOutputPart` with correct MIME + bytes.
  - Validate that cached OutputState is read and updated after onDidChangeHeight events.
- Integration
  - Simulate a tool invocation that produces webview output, hide/show the chat widget and assert `reinitialize()` is called and that height is preserved.
  - Wheel event bridging: simulate a wheel event from the rendered webview and assert the containing chat widget receives delegated scroll calls.
- E2E
  - Full flow: invoke a tool that produces a downloadable artifact; ensure Save/Download path works (uses file APIs) and UI shows progress placeholder then final rendered output.

Short prioritized porting checklist (concrete steps)
1. Implement (or wrap) a webview-like renderer with:
   - creation, dispose, reinitialize,
   - a promised render API accepting (mimeType, bytes, parent, options.origin, token),
   - events onDidChangeHeight and onDidWheel. (High)
2. Port `IChatOutputRendererService` semantics so output renderers can be contributed and activated per mime type. (High)
3. Replicate in-memory caching strategy for OutputState keyed by widget view-model + toolCallId (WeakMap). (Medium)
4. Wire host scroll delegation API (delegateScrollFromMouseWheelEvent) to accept wheel events from rendered webview. (Medium)
5. Support serialized tool invocation payloads (base64 decode path) and provide safe temporary URI handling for binary outputs. (Medium)
6. Add unit and integration tests for the behaviors above. (Medium)

Cross-links
- Tool output renderers and webview details: [`product_description/features/chat/output_and_sessions.md:1`](product_description/features/chat/output_and_sessions.md:1)
- I/O parts & save flow: [`product_description/features/chat/markdown_and_io.md:1`](product_description/features/chat/markdown_and_io.md:1)
- Attachments & privacy: [`product_description/features/chat/attachments_and_markdown.md:1`](product_description/features/chat/attachments_and_markdown.md:1)

References (quick jump)
- [`ChatToolOutputSubPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:30)
- [`renderOutputPart(...)` call site`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:111)
- [`ChatToolInvocationPart.createToolInvocationSubPart()` routing logic](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:82)

End of notes.
