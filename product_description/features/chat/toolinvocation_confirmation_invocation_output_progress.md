Tool invocation: Confirmation, Invocation orchestration, Output rendering & Progress

Summary
This doc synthesizes the responsibilities, flows, lifecycle contracts and porting notes for the remaining tool-invocation subparts and orchestration layer.

Key files
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolConfirmationSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolConfirmationSubPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1)

Responsibilities (per-component)
- ToolConfirmationSubPart
  - Render rich confirmation UX for tool invocations (string or structured message).
  - When structured: render editable codeblock input models, validate via JSON schema (json.validate), show diagnostics via IMarkerService.
  - Provide multiple "Allow" choices (session/workspace/global) and wire these to ILanguageModelToolsService to persist auto-confirmation preferences.
  - Expose height changes, remember to reset ChatContextKeys.Editing.hasToolConfirmation on completion.
- ChatToolInvocationPart
  - Orchestrator for tool subparts: selects the right subpart type based on toolInvocation shape (terminal, extensions, input/output, result list, output rendering or progress).
  - Supports rerender on model changes (subpart.onNeedsRerender).
  - Exposes aggregate codeblocks and codeblocksPartId from current subPart.
- BaseChatToolInvocationSubPart
  - Common base: tracks codeblocksPartId, exposes onNeedsRerender and onDidChangeHeight events, sets up isCompletePromise -> rerender hook.
- ChatToolOutputSubPart
  - Renders binary/HTML/webview tool output via IChatOutputRendererService; uses per-view-model WeakMap cache to store OutputState (webviewOrigin + height).
  - Shows progress spinner while webview rendering occurs; registers renderedItem.onDidChangeHeight to persist height to cached state.
  - Wires webview.onDidWheel to chatWidgetService.delegateScrollFromMouseWheelEvent and reinitialize() when widget shows again.
- ChatToolProgressSubPart
  - Renders progress messages for tool calls using ChatProgressContentPart; observes toolInvocation.progress autorun to update message/title and show appropriate icon (error/check/loading).

Injected services & dependencies (not exhaustive)
- IInstantiationService, IModelService, ILanguageService, IMarkerService, ICommandService (json.validate), ILanguageModelToolsService.
- IChatOutputRendererService and IChatWidgetService for webview-based output rendering and scroll delegation.
- EditorPool / ResourcePool, CodeBlockModelCollection for codeblock lifecycle and streaming semantics.
- Context key bindings and keybinding lookups to show Continue/Cancel key labels.

UI flows & interactions
- Confirmation flow:
  - For structured confirmations, create an ephemeral model via modelService.createModel(..., true) with unique tool input URI (createToolInputUri/createToolSchemaUri).
  - Validate content via json.validate command and display markers; "See more" toggles expand of inline JSON preview.
  - Buttons include primary "Continue" and optionally dropdown for session/workspace/global allow options; button click completes toolInvocation.confirmed promise and triggers _onNeedsRerender.
- Invocation selection & rerender:
  - ChatToolInvocationPart chooses subpart by checking: toolSpecificData kind, confirmationMessages, resultDetails shape (input/output, output-only, result list), or falls back to progress subpart.
  - Subparts may call this._onNeedsRerender.fire() to request the parent ChatToolInvocationPart re-render (used after confirmation/completion).
- Output rendering:
  - ChatToolOutputSubPart delegates to IChatOutputRendererService.renderOutputPart(mime, buffer, parent, { origin }, token) and then registers lifecycle handlers (onDidChangeHeight, webview.onDidWheel, reinitialize on widget.show).
  - Caches OutputState per viewModel + toolCallId to persist height & webview origin across rerenders.
- Progress updates:
  - ChatToolProgressSubPart uses autorun to read toolInvocation.progress and render spinner/title accordingly using ChatProgressContentPart.

Lifecycle patterns & important contracts
- Ephemeral models: models created with createModel(..., true) must be disposed; parts register models with _register so owner disposal cleans them up.
- Pool semantics: EditorPool/ResourcePool return IDisposableReference wrappers with object, isStale flag and dispose() that resets and releases back to pool — preserve these semantics precisely.
- Cached OutputState: stored in WeakMap keyed by viewModel; must preserve origin and height to avoid recreating/reinitializing different webview instances inadvertently.
- Confirmation promise: toolInvocation.confirmed is a PromiseCompletionSource that UI completes; callers await confirmed.p then trigger rerender or follow-up logic.

Porting considerations & risks (high-risk items)
- Webview contract: IChatOutputRendererService.RenderedOutputPart must support onDidChangeHeight, webview.onDidWheel, reinitialize() and be safe to dispose; host must implement similar contract or adapter.
- JSON validation command: relies on 'json.validate' command and schema URI plumbing; port must provide equivalent validation mechanism and marker semantics.
- Persistent allow settings: ILanguageModelToolsService.setToolAutoConfirmation used to persist allow settings at different scopes; ensure host has policy storage or equivalent.
- Editor/model streaming & codemapper: codeblock streaming/codemapper URIs rely on CodeBlockModelCollection; preserve updating pattern (updateSync + async update) to avoid race conditions.
- Cancellation & disposal: ChatToolOutputSubPart uses CancellationTokenSource to cancel render; ensure render cancellation semantics exist in host renderer.
- Keyboard/context keys: ChatContextKeys modifications must be ported to host context key system to keep UI state consistent (hasToolConfirmation).

Test ideas and verification
- Unit: ToolConfirmationSubPart needs tests for:
  - structured message -> ephemeral model created, json.validate invoked, markers updated on schema result.
  - buttons choices call languageModelToolsService.setToolAutoConfirmation with correct scope.
- Integration: ChatToolOutputSubPart
  - mock IChatOutputRendererService to return fake RenderedOutputPart; verify onDidChangeHeight wiring, webview.onDidWheel mapping to delegate scroll, and reinitialize called when widget shows.
- Integration: ChatToolInvocationPart rerender path
  - simulate toolInvocation.confirmed resolution and ensure subpart rerenders and aggregated codeblock lists update.
- Pool tests: EditorPool get/dispose/reuse/isStale semantics.

Verbatim patterns to preserve (important)
- Output cache pattern:
  const _cachedStates = new WeakMap<IChatViewModel | IChatToolInvocationSerialized, Map<string, OutputState>>();
- Base subpart id pattern:
  public readonly codeblocksPartId = 'tool-' + (BaseChatToolInvocationSubPart.idPool++);
- Render output wiring:
  chatOutputItemRendererService.renderOutputPart(mime, buffer, parent, { origin }, token).then(renderedItem => { register(renderedItem); renderedItem.onDidChangeHeight(newHeight => partState.height = newHeight); renderedItem.webview.onDidWheel(... delegateScrollFromMouseWheelEvent) });

Accessibility notes
- Confirmation widgets already manage focus and notifications; maintain host focus/notification behavior (triggerNotification, hostService.focus).
- Ensure webview and rendered output parts expose appropriate keyboard/aria contracts if interactive.

Next steps
- Add this doc to the MANIFEST and mark these tool-invocation subparts as covered.
- Continue with QA pass: cross-link all created docs, run final checklist, and finalize product_description/MANIFEST.md and OVERVIEW.md.
