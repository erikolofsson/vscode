Chat: Tool Invocation — Extensions, I/O, Terminal & Result Lists

Summary
This document summarizes responsibilities, UI flows, lifecycle patterns, injected services and porting considerations for tool-invocation related content parts.

Key files
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatExtensionsInstallToolSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatExtensionsInstallToolSubPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatInputOutputMarkdownProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatInputOutputMarkdownProgressPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatResultListSubPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalMarkdownProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalMarkdownProgressPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalToolSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalToolSubPart.ts:1)

Responsibilities (per-component)
- Extensions install: render ExtensionsList, show confirmation widget with Continue/Cancel, enable Continue after extensionManagementService.onInstallExtension detects install.
- Input/Output collapsible: render tool input as a pooled editor/codeblock and outputs as code or data attachments; generate permalink URIs for binary outputs via ChatResponseResource.createUri.
- Result list: render collapsible reference list of result locations (URIs/Locations) via CollapsibleListPool.
- Terminal markdown progress: render terminal command as a markdown codeblock using ChatMarkdownContentPart, show progress icon (loading/check/error) via ChatCustomProgressPart.
- Terminal confirmation: render editable codeblock model user can edit, wire confirmation buttons to toolInvocation.confirmed, and persist edited command into terminalData.commandLine.userEdited.

Injected services & runtime dependencies
- IInstantiationService, IEditorService, IModelService, ILanguageService, IExtensionManagementService.
- Editor pooling: EditorPool (backed by ResourcePool) used to obtain editors for codeblocks.
- Chat widget & context keys: IChatWidgetService, ChatContextKeys for hasToolConfirmation state.
- Menu/toolbar/Keybindings: IKeybindingService for showing keybinding labels for Continue/Cancel actions.

UI flows
- Extensions flow: create ChatExtensionsContentPart, show ChatConfirmationWidget; on install event enable Continue button and complete toolInvocation.confirmed promise.
- Input/output flow: create ephemeral models for input JSON (modelService.createModel(..., true)), build output parts array mapping embeds/ref/binary to either code parts or data parts with generated URIs, pass to ChatCollapsibleInputOutputContentPart.
- Result list flow: map tool result URIs/Locations to IChatCollapsibleListItem and render via ChatCollapsibleListContentPart obtained from CollapsibleListPool.
- Terminal flow: create ephemeral model (modelService.createModel) with a unique URI (Schemas.vscodeChatCodeBlock + generateUuid()), render editor from EditorPool, wire model.onDidChangeContent to update terminalData.commandLine.userEdited, show ChatCustomConfirmationWidget with rendered markdown.

Lifecycle patterns & contracts
- Promise-based confirmation: toolInvocation.confirmed is completed when user clicks confirmation; callers subscribe to p.then() and call _onNeedsRerender.
- Editor ephemeral models: models created with modelService.createModel(..., true) must be disposed when part disposes; EditorPool ref disposal calls reset() and returns editor to pool.
- Expanded state memory: ChatInputOutputMarkdownProgressPart._expandedByDefault WeakMap preserves expanded state per toolInvocation across re-renders.
- Generated permalinks: outputs without external URI are persisted under ChatResponseResource.createUri(sessionId, requestId, toolCallId, index, basename) and must be readable via file service or host storage.

Porting considerations & risks
- Extension install detection: relies on IExtensionManagementService.onInstallExtension and areSameExtensions for matching; host must expose extension lifecycles or provide adapter.
- Binary output handling: decoding base64 and creating in-repo URIs assumes file-service like APIs and storage for large binary blobs; streaming limits and memory pressure must be addressed.
- Editor pooling: preserve ResourcePool IDisposableReference semantics (isStale flag, dispose resets object and releases back to pool) to avoid reuse-after-dispose races.
- Ephemeral model URIs: code assumes Schemas.vscodeChatCodeBlock ephemeral URIs with generateUuid; host needs equivalent scheme and model-resolver semantics.
- Multi-diff/multi-editor UX: tools opening diffs or editors across groups use editorGroupsService and MultiDiffEditorInput; if platform lacks multi-diff, provide fallback.

Verbatim/important patterns to preserve
- Expanded-state weak map:
  const _expandedByDefault = new WeakMap<IChatToolInvocation | IChatToolInvocationSerialized, boolean>();
- Generating permalinks for outputs:
  const permalinkUri = ChatResponseResource.createUri(context.element.sessionId, requestId, toolInvocation.toolCallId, i, permalinkBasename);
- Editor ephemeral model creation:
  modelService.createModel(data, languageService.createById('json'), undefined, true)
- Unique codeblock URI for terminal editable model:
  URI.from({ scheme: Schemas.vscodeChatCodeBlock, path: generateUuid() });

Tests and verification
- Unit: ExtensionsInstallConfirmationWidgetSubPart should enable Continue only after matching extension install event and complete the confirmation promise.
- Unit: ChatInputOutputMarkdownProgressPart maps outputs correctly to code/data parts and generates permalinks with predictable basename.
- Integration: TerminalConfirmationWidgetSubPart editing model writes back into terminalData.commandLine.userEdited and confirmation completes.
- Integration: EditorPool reuse test: get(), render, dispose(), get() again => reset called and isStale behavior verified.

Accessibility notes
- Confirmation widgets use ChatCustomConfirmationWidget / ChatConfirmationWidget; ensure focus management, notification triggering and ARIA labels are preserved.
- Terminal codeblock editors set ariaLabel to the confirmation title for screen-reader context.

Next steps
- Add this doc to product_description/MANIFEST.md and continue with remaining toolInvocationParts: [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolConfirmationSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolConfirmationSubPart.ts:1), [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationPart.ts:1), [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolInvocationSubPart.ts:1), [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolOutputPart.ts:1), [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolProgressPart.ts:1)

End
