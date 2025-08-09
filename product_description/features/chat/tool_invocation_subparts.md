# Tool Invocation Subparts — Chat subsystem

Summary:
- This document captures responsibilities, injected services, UI flows, lifecycle patterns, and porting considerations for the chat "tool invocation" subparts: confirmations, terminal/tool progress, input/output rendering, result lists and webview-based tool outputs.

Related implementation files (read)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatInputOutputMarkdownProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatInputOutputMarkdownProgressPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolConfirmationSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolConfirmationSubPart.ts:1)
- Additional subparts referenced:
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalToolSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalToolSubPart.ts:1)
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:1)
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatExtensionsInstallToolSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatExtensionsInstallToolSubPart.ts:1)
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1)

Responsibilities
- Orchestration
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1) is the top-level part that chooses and mounts the appropriate sub-part for a given toolInvocation instance. It supports rerendering when the underlying (mutable) toolInvocation model changes.
- Confirmation UI
  - Confirmation flows (user must approve tool runs) are implemented in [`chatToolConfirmationSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolConfirmationSubPart.ts:1).
  - Presents choices (Allow, Disallow, AllowWorkspace, AllowGlobally, etc.), optional editable input payloads (JSON editor view), validation, and "See more" expansion for long content.
- Terminal and command flows
  - Terminal-specific confirmations and terminal progress rendering live in [`chatTerminalToolSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalToolSubPart.ts:1) and terminal-progress variants.
- Input/Output presentation
  - `ChatInputOutputMarkdownProgressPart` (`chatInputOutputMarkdownProgressPart.ts:1`) renders paired input and output, with collapsible sections and code/attachments. It converts output items into data parts (permalink URIs, embedded data, or code panes).
- Result listing
  - `ChatResultListSubPart` groups multiple result items into a collapsible list using `CollapsibleListPool` and list renderers.
- Tool output rendering
  - `ChatToolOutputSubPart` (`chatToolOutputPart.ts:1`) renders arbitrary output via `IChatOutputRendererService`. It:
    - Shows a loading progress placeholder.
    - Obtains/creates a webview via ChatOutputRendererService and mounts it into the part.
    - Tracks and caches per-toolCallId webview origin and last height in a WeakMap keyed by viewModel, to persist webview origin & height across re-renders.
    - Registers onDidChangeHeight to update parent height and wires webview wheel events back into the widget's scroll delegate.
    - Calls renderedItem.reinitialize() when the containing widget becomes visible again.

Key UI flows & lifecycle
- Subpart selection
  - The top-level invocation part evaluates: confirmation-needed → confirmation subpart; terminal/tool-specific → terminal subpart; array result → result-list subpart; input/output details → input-output subpart; single output data → tool-output subpart. See [`chatToolInvocationPart.ts:82`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:82).
- Rerender on model changes
  - `BaseChatToolInvocationSubPart` registers toolInvocation.isCompletePromise to fire onNeedsRerender for streaming toolInvocations (see [`chatToolInvocationSubPart.ts:25`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:25)).
  - The top-level part fully clears & re-creates the subpart when a rerender is requested (safe but destructive pattern).
- Webview lifecycle & caching
  - Webview origin (random UUID) is preserved per viewModel+toolCallId so that subsequent renders reuse the same origin where possible. Height is cached and applied to style.height to reduce reflows. See [`chatToolOutputPart.ts:24`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:24).
  - Reinitialize after dismount: when widget shows again, reinitialize() is called on rendered item to re-establish content.
- Input editing & validation
  - Confirmation subpart (ToolConfirmationSubPart) creates a temporary model for JSON input and schedules schema validation using `json.validate` command, syncing markers to the model via MarkerService. It uses EditorPool for creating an editable code block UI and tracks content height changes to re-layout parent.

Injected services / dependencies (summary)
- IInstantiationService — to create subparts & resource labels
- MarkdownRenderer — for rendering invocation / origin messages
- EditorPool / CollapsibleListPool — pooling for editors and lists
- IChatOutputRendererService — render arbitrary MIME tool outputs in webviews
- IChatWidgetService — widget and scroll delegation hooks
- IModelService / ILanguageService / MarkerService — creating temp models and validation (confirmation/input)
- ICommandService — used for editor/validation commands and opening editors
- IChatMarkdownAnchorService / other chat infrastructure services used by subparts

Porting checklist (prioritized)
1) Webview output surface & renderer activation — HIGH (Effort: M-L)
   - Implement or adapt a webview API that provides:
     - mounting to a DOM parent,
     - an intrinsicContentSize observable (or event) for height,
     - reinitializeAfterDismount(),
     - onDidWheel events.
   - Provide `IChatOutputRendererService` extension/contribution activation flow (ExtensionsRegistry point) and ensure extension activation by event `onChatOutputRenderer:<viewType>` works or provide a shim.

2) Tool invocation model mutability & rerender semantics — HIGH (Effort: S-M)
   - Preserve ability to rerender subparts when toolInvocation changes (isCompletePromise, confirmed promise).
   - Recreate subpart safely on rerender — acceptable pattern, but ensure state not lost for important UX (e.g., scroll position in large outputs).

3) EditorPool & codeblock embedding — HIGH (Effort: M)
   - Provide pooled CodeBlock editors (EditorPool) and ensure onDidChangeContentHeight events are available and trigger parent layout.

4) Temporary models & schema validation — MEDIUM (Effort: M)
   - Implement model creation for tool input previews with schema-based validation via a command (or provide synchronous validator).
   - Ensure marker service or equivalent exists to attach validation markers to ephemeral models.

5) Confirmation controls & actions — MEDIUM (Effort: S)
   - Provide ChatConfirmationWidget and ChatCustomConfirmationWidget or equivalent modal / inline confirmation controls with additional actions (allow workspace, allow always).

6) Result lists & collapsible IO parts — MEDIUM (Effort: S-M)
   - Port `ChatCollapsibleInputOutputContentPart` and `CollapsibleListPool` usage patterns for grouped results and input/output parts.

7) Caching & persistence of webview metadata — LOW (Effort: S)
   - Implement caching of webview origin + last height per viewModel (WeakMap approach) to reduce reinitialization churn.

Tests & verification
- Unit
  - BaseChatToolInvocationSubPart triggers onNeedsRerender when toolInvocation.isCompletePromise resolves.
  - ChatToolOutputSubPart caches and restores webview origin & height correctly (WeakMap semantics).
- Integration
  - When a tool produces a webview output renderer, parent height updates when renderedItem.onDidChangeHeight fires.
  - Reinitialize runs when container is shown again and webview is re-mounted.
- E2E
  - Simulate a tool invocation that:
    - requires confirmation → user selects allow/disallow; check that toolInvocation.confirmed resolves and UI rerenders.
    - produces binary/image output → `IChatOutputRendererService` renders via webview; height updates and wheel events delegate to widget.

Risks & mitigations
- Risk: Host platform lacks webview intrinsic sizing & reinitialize semantics.
  - Mitigation: Provide an adapter that exposes minimal surface (mount/unmount, resize event, reinitialize). Emulate intrinsic size via postMessage from inside webview if necessary.
- Risk: Recreating subparts loses ephemeral UI state (e.g., scroll, focus).
  - Mitigation: Persist minimal state when rerendering if required (e.g., store last-scroll offset in subpart state cache or in the widget viewModel).
- Risk: Schema validation command not available
  - Mitigation: Make validation optional or fall back to no-op validation. Add a migration note.

Actionable next steps
- Implement a small webview adapter and stub `IChatOutputRendererService` consumer with a test renderer to validate height & reinitialize flows.
- Add unit tests for subpart rerender/signalling (toolInvocation.isCompletePromise -> onNeedsRerender).
- Port EditorPool & ChatConfirmationWidget for interactive confirmations and input editing.

References
- See implementation files listed at the top for exact call-sites and code examples.
