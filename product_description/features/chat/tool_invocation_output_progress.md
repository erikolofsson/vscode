# Chat — Tool Invocation: Invocation Selection, Output Rendering & Progress

Summary of batch read (files)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1)

Responsibilities
- Orchestrates selection and rendering of the correct tool-invocation sub-part based on toolInvocation.kind, toolSpecificData, resultDetails and confirmation state (see [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1)).
- Render progress messages and final outcomes for tool invocations (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1)`).
- Render binary/complex tool outputs through the registered output renderer service and manage webview lifecycle, caching per viewModel + toolCallId (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1)`).
- Render result lists (references / locations) as collapsible lists reusing the list pool (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:1)`).
- Provide base sub-part semantics (rerender triggers, height changes, codeblocksPart ids) for all tool-invocation subparts (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:1)`).

Injected services & dependencies
- MarkdownRenderer, EditorPool, CollapsibleListPool, CodeBlockModelCollection for rendering markdown and pooled editors (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1)`).
- IChatOutputRendererService and IChatWidgetService for webview-based output rendering and event delegation (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1)`).
- IInstantiationService used heavily to create subparts dynamically and manage lifecycle (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1)`).
- Observable progress objects and autorun used to update progress parts (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1)`).

UI flows & interactions
- Creation flow: ChatToolInvocationPart.createToolInvocationSubPart chooses one of:
  - extension install confirmation (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatExtensionsInstallToolSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatExtensionsInstallToolSubPart.ts:1)`)
  - terminal confirmation / terminal progress (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalToolSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalToolSubPart.ts:1)`, [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalMarkdownProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalMarkdownProgressPart.ts:1)`)
  - result list (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:1)`)
  - output renderer (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1)`)
  - input/output collapsible (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatInputOutputMarkdownProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatInputOutputMarkdownProgressPart.ts:1)`)
- Rerender flow: sub-parts can signal onNeedsRerender to trigger ChatToolInvocationPart.render which recreates and rebinds a new subPart instance (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:66`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:66-79)`).
- Progress updates: ChatToolProgressSubPart observes toolInvocation.progress (autorun) and swaps rendered content using ChatProgressContentPart (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:41-46`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:41-46)`).
- Output rendering: ChatToolOutputSubPart requests renderOutputPart(mime, buffer, parent, { origin }, token). It shows a progress spinner, replaces it with the rendered webview, wires onDidChangeHeight and webview.onDidWheel to delegate scrolls, and reinitializes on widget show (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:111`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:111-141)`).

Patterns & lifecycle
- Sub-parts derive from BaseChatToolInvocationSubPart which assigns a stable codeblocksPartId and listens for isCompletePromise to fire rerender requests (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:23-33`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:23-33)`).
- WeakMap caching per viewModel used by ChatToolOutputSubPart to persist webview origin + last known height across rerenders (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:32-39`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:32-39)`).
- DisposableStore per ChatToolInvocationPart allows full sub-part teardown and recreation on rerender (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:66`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:66-79)`).
- Use of pooled UI widgets (EditorPool, CollapsibleListPool) to reuse heavy DOM/editor instances and avoid allocation storms.

Porting considerations & risks
- Webview-based renderer: requires platform adapter exposing a renderOutputPart-like API that returns a reinitializable RenderedOutputPart with onDidChangeHeight and webview event hooks (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:111`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:111)`).
- Scroll delegation: webview.onDidWheel → delegateScrollFromMouseWheelEvent must be supported to maintain expected scrolling behavior inside chat widget (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:126-131`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:126-131)`).
- Cached state correctness: WeakMap per IChatViewModel means viewModel identity must be preserved; if host uses immutable view models, adapt caching strategy (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:32-39`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:32-39)`).
- Rerender semantics: toolInvocation is mutable and parts expect to be able to re-create subparts; a host that treats models as immutable must provide a rerender signal or wrapper to allow sub-part recreation (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:63-79`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:63-79)`).
- Progress observability: ensure autorun/observable read model or equivalent reactive primitives are available or polyfilled for progress updates (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:41-46`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:41-46)`).

Suggested tests
- Render selection: assert ChatToolInvocationPart.createToolInvocationSubPart returns correct subpart type for each toolInvocation shape (terminal, extensions, resultDetails array, output details, input/output details).
- Webview lifecycle: mock IChatOutputRendererService to return a fake RenderedOutputPart and verify onDidChangeHeight wiring, reinitialize on widget show, and scroll delegation invocation.
- Rerender behavior: when toolInvocation.isCompletePromise resolves, ensure subpart re-creation happens and height change fires.

Next automated actions
1. Save this synthesized doc to product_description/features/chat/ (this file)
2. Update TODO to mark this batch completed
3. Continue reading the next prioritized batch of chat contentParts (remaining files in the directory) and synthesize into the next feature doc

Notes for implementer
- Preserve exact function of renderOutputPart and the RenderedOutputPart contract when porting; it's the highest-risk native integration in this batch.
- Keep pooled-editor and list-pool semantics intact; add unit tests that assert pool reuse and isStale semantics.
- When mocking in tests, stub generateUuid and viewModel lookup to produce deterministic cachedState keys.
