# Chat — Tool Invocation Subparts (batch)

Summary of batch read (files)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:1)

Responsibilities
- Orchestrate tool invocation rendering and choose appropriate sub-part based on invocation shape: [`ChatToolInvocationPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:29)
- Render webview-backed tool outputs and manage cached per-viewModel origin/height state: [`ChatToolOutputSubPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:30)
- Provide a base contract for sub-parts that can signal rerender and height changes: [`BaseChatToolInvocationSubPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:11)
- Render progress / terminal / input-output flows for tool calls: [`ChatToolProgressSubPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:18)
- Render result lists using collapsible reference lists: [`ChatResultListSubPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:16)

Injected services & dependencies
- MarkdownRenderer + IInstantiationService (used to create sub-parts) — see [`chatToolInvocationPart.ts:48`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:48)
- IChatOutputRendererService for rendering arbitrary mime outputs (webview/elements) — referenced in [`chatToolOutputPart.ts:44`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:44)
- IChatWidgetService for widget lifecycle, viewModel lookup and scroll delegation — referenced in [`chatToolOutputPart.ts:45`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:45)
- Shared pools & collections injected by parent: `CollapsibleListPool`, `EditorPool`, `CodeBlockModelCollection` (see [`chatToolInvocationPart.ts:49-53`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:49))

UI flows & interactions
- ChatToolInvocationPart uses `createToolInvocationSubPart()` to select the correct rendering sub-part based on invocation shape (extensions confirmation, terminal, input/output, result lists, or generic progress) and mounts it into the DOM; it re-renders when the sub-part fires `onNeedsRerender()` (see [`createToolInvocationSubPart()`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:82)).
- Tool output rendering shows a small progress indication while the `IChatOutputRendererService.renderOutputPart` promise resolves; once resolved the RenderedOutputPart is registered, progress removed, and listeners are wired:
  - onDidChangeHeight → parent onDidChangeHeight (keep size in sync)
  - webview.onDidWheel → delegateScrollFromMouseWheelEvent to allow the chat list to scroll (see [`chatToolOutputPart.ts:116-132`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:116))
  - widget.onDidShow → call `renderedItem.reinitialize()` to reload webview after hidden/dismount (see [`chatToolOutputPart.ts:136-139`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:136))
- Result lists render using `ChatCollapsibleListContentPart` and wire opener/context menu on items (see [`ChatResultListSubPart` creation](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:30))

Lifecycle & pooling patterns
- Sub-parts are Disposable and expose:
  - onNeedsRerender: parent can replace the sub-part DOM when underlying model completes/changes (`BaseChatToolInvocationSubPart:onNeedsRerender` at [`chatToolInvocationSubPart.ts:15`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:15))
  - onDidChangeHeight: used by parent to update layout
- Shared UI controls are pooled (EditorPool, CollapsibleListPool) and injected into sub-parts to reduce allocation pressure (see [`chatToolInvocationPart.ts:49-51`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:49))
- ChatToolOutputSubPart uses a CancellationTokenSource to cancel in-flight render work when disposed (see [`chatToolOutputPart.ts:39`, `chatToolOutputPart.ts:74`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:39))

Porting considerations & risks
- Webview intrinsic sizing and reinitialize semantics are high-risk: the output renderer expects a webview-like element that:
  - reports intrinsicContentSize / onDidChangeHeight
  - allows setting a stable origin/token for messaging
  - supports reinitializeAfterDismount or similar to recreate state when remounted
  Implement an adapter layer if the target platform's webview is different. See [`chatToolOutputPart.ts:111-139`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:111).
- WeakMap caching for per-viewModel output state (webviewOrigin, height) assumes predictable GC/wrapper lifetime; if platform GC differs, use a lifecycle-managed Map keyed by widget id instead of WeakMap. See [`chatToolOutputPart.ts:32`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:32).
- Cancellation and disposal: ensure CancellationTokenSource-like semantics to abort long-running renders to avoid resource leaks.
- Wheel event forwarding: webview output must surface wheel events or expose a hook so the containing chat list can receive delegated scroll events.
- Sub-part rerender triggers: `toolInvocation.isCompletePromise.then(() => this._onNeedsRerender.fire())` pattern depends on the toolInvocation model exposing completion promises — preserve that contract or adapt.

Suggested tests (unit / integration)
- Sub-part selection: assert `createToolInvocationSubPart()` returns expected sub-part types for different `IChatToolInvocation` shapes (extensions, terminal, input/output, lists) (see logic at [`chatToolInvocationPart.ts:82`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:82)).
- Webview output lifecycle: mock `IChatOutputRendererService.renderOutputPart` to return a fake RenderedOutputPart and assert:
  - progress indicator is removed after resolution
  - onDidChangeHeight updates are wired
  - renderedItem.reinitialize() is called when widget emits onDidShow (see `chatToolOutputPart.ts:116-139`).
- Cancellation: ensure disposing ChatToolOutputSubPart cancels pending render and does not register listeners after disposal (CancellationTokenSource behavior).
- Result list rendering: integration test to ensure CollapsibleListPool is used and list open/context actions call openerService/context menu actions correctly (see `ChatResultListSubPart`).

Next automated actions
1. Add this synthesized note into the feature docset (this file).
2. Mark this batch completed in the TODO and continue scanning remaining chatContentParts/toolInvocationParts.

Notes for implementer
- Consider adding a small adaptor interface for output renderers:
  - create(options) → RenderedOutputPart { webview, onDidChangeHeight, reinitialize(), dispose() }
  - ensures consistent behavior across platforms and simplifies tests.
- Keep the webview origin stable per toolCallId for message scoping; if WeakMap is unreliable, store state keyed by a stable widget id.
