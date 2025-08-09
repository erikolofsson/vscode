# Chat — Context, Copy, Execute & Developer Actions

Summary:
This feature doc covers the chat subsystem actions that handle context attachment, quick-picks for context, copy semantics, developer utilities, and execution/submit flows. It synthesizes responsibilities, key APIs, lifecycles, user flows, porting risks and test ideas.

Source files (primary)
- [`src/vs/workbench/contrib/chat/browser/actions/chatContext.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatContext.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatCopyActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatCopyActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatDeveloperActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatDeveloperActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatExecuteActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatExecuteActions.ts:1)

Responsibilities
- Provide UI and command bindings for attaching context to chat requests: open editors, related files, images from clipboard, screenshots, tools.
- Present picker UI (quickpick / quick access) with provider extension points for feature areas to add contextual picks.
- Normalize picked items into chat-request variable entries (file, image, tool, generic symbol) and add them to the widget attachment model.
- Copy semantics for full session, single items, and inline selection behavior.
- Developer-only actions for logging internal state (input history, chat index).
- Execute/submit flows: primary submit, submit-with-codebase, submit-to-new-chat, cancel, pause/resume, remote agent delegation, model/mode switching and editing-session submit.

Key runtime concepts & patterns
- Attachment model: widget.attachmentModel is the single place where attachments (file, image, tool, generic) are collected.
- Context providers: registered implementations of IChatContextValueItem and IChatContextPickerItem are surfaced by the chat context contributions.
- QuickAccess integration: AttachContextAction uses the Anything/Symbols/Goto providers and platform quick pick to offer heterogeneous picks and providerOptions with handleAccept hooks.
- Text-model probing: before attaching a file, the code attempts to createModelReference(uri) to detect whether the file can be resolved and to decide omittedState (Full / NotOmitted).
- Image handling: binary image reads from file or clipboard are resized and converted to image variable entries; imageToHash produces stable ids.
- Execution guardrails: SubmitAction handles editing-session checks, confirmation dialogs when undoing edits, telemetry, and mode-specific preconditions.

UX flows (high-level)
- User triggers "Add Context..." (toolbar or keybinding). The AttachContextAction opens quick-access with:
  - built-in picks (tools, open editors, related files, clipboard image, screenshot),
  - provider picks from other platforms (symbols, search results, file picker).
- Selecting a pick converts it to a chat variable entry and calls widget.attachmentModel.addContext(...) and focuses input (unless chosen in background).
- For file picks, the system attempts to create a text model reference to detect omitted state (if model cannot be created, mark as omitted/full).
- Copy flow: CopyItemAction copies selection if text selected and focus is inside the widget DOM (getActiveWindow().getSelection()).
- Submit flow: ChatSubmitAction and variants observe ChatContextKeys, enforce preconditions, interact with editing sessions, present confirmation dialogs when appropriate, and call widget.acceptInput(...) to enqueue requests.

Lifecycles & call-sites
- ChatContextContributions registers default context picks at workbench contribution time (Tools, Instructions, Open Editors, Related Files, Clipboard Image, Screenshot).
- The quick-pick provider may invoke text model creation and file reads; these are synchronous/async and must be cancellable by the user hiding the picker.
- AttachmentModel receives variable entries and maintains reference ids; downstream request creation serializes these entries into the request payload.
- SubmitAction consults IChatService to find the session model, checks editingSession snapshots, and may call session.restoreSnapshot(...) when undoing requests.

Porting risks & fragilities
- QuickPick & QuickAccess differences: host platforms lacking the same quick access providers or "additionPicks" extension points will need an alternate UI. The AnythingQuickAccess heavy integration is platform-specific.
- Model resolution (createModelReference): Hosts that don't provide editor model resolution will cause omittedState fallbacks. Port must provide a safe fallback (try to open a file or mark omitted, avoid throwing).
- Binary image resizing and clipboard APIs: convertBufferToScreenshotVariable, clipboardService.readImage and fileService.readFile are platform services; absent or differing APIs require shims or simplified image attach UX.
- Cancellation semantics: picker uses CancellationTokenSource; ports must offer cancellable async pick providers or ensure hiding the picker cancels background work to avoid leaked promises.
- ContextKeyExpr visibility: action/menu visibility relies on the VS Code context key system. When porting to hosts without the same system, either implement a simplified predicate system or expose actions via a less granular menu strategy.
- Telemetry & user prompts: SubmitAction uses dialogService and telemetry. Ports should avoid blocking dialogs in non-interactive or constrained environments and ensure telemetry calls are optional.

Recommended mitigations
- Provide a minimal picker UI that supports grouped picks and background accept; implement a fallback path that shows a simple list when AnythingQuickAccess is unavailable.
- For model resolution failures, prefer marking files as omitted (Full) instead of throwing and present the user an option to attach the file anyway.
- Abstract clipboard/image access behind a small adapter that allows the host to return "not supported" quickly; the chat UI should then hide image-based picks from capability-lacking hosts.
- Implement request cancellation and picker cancellation using a shared CancellationToken abstraction; tie lifecycle of async providers to picker visibility.

Test & QA recommendations
- Unit tests:
  - ContextPick toAttachment conversions (tool -> tool entry, files -> file entries with omittedState decisions).
  - Copy behavior: selection-copy vs whole-item-copy, stringifyItem outputs.
  - SubmitAction editing-session undo prompt logic (with mocked configurationService and dialogService).
- Integration tests:
  - Quick-pick end-to-end attach: simulate provider picks, file/image attachments, and confirm widget.attachmentModel state.
  - Remote agent delegation: CreateRemoteAgentJobAction flow with mocked remote agent command returning both string and structured pull-request-like responses.
- Manual UX tests:
  - Keyboard flow for AttachContextAction (open -> pick -> background accept -> input focus).
  - Paste image from clipboard path when language model supports vision capabilities.

Implementation notes & cross-links
- This doc intersects heavily with:
  - code block apply/insert operations: [`src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:1`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:1)
  - attachment widget & editor internals: [`product_description/features/chat/attachments_widget_and_editor.md:1`](product_description/features/chat/attachments_widget_and_editor.md:1)
  - tool picker and tool actions: [`src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:1)
  - submit/execute and editing session flows: [`src/vs/workbench/contrib/chat/browser/actions/chatExecuteActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatExecuteActions.ts:1)

Source-level callouts
- chatContext.ts registers default context picks as a workbench contribution (ChatContextContributions), instantiate points: ToolsContextPickerPick, OpenEditorContextValuePick, RelatedFilesContextPickerPick, ClipboardImageContextValuePick, ScreenshotContextValuePick.
- chatContextActions.ts provides AttachContextAction and a family of Attach* actions (file/folder/selection/search results) as Action2 registrations and wires quick-access providerOptions, background accept and cancellation.
- chatCopyActions.ts implements CopyAll and CopyItem semantics. CopyItem preserves native selection copy when the selection is inside the widget DOM (getActiveWindow().getSelection()).
- chatDeveloperActions.ts registers internal developer actions for logging input history and chat index; these are gated by ChatContextKeys.enabled and categorized under Developer actions.
- chatExecuteActions.ts is the central place for send/submit/cancel/pause/resume, model/mode pickers, remote agent delegation, and complex editing-session confirmation flows.

Porting checklist (recommended minimal moves)
- Ensure a picker component exists that supports:
  - grouped separators,
  - background accepts (accept without closing the picker),
  - cancellation observable when picker hides.
- Provide the following platform services or equivalents:
  - file read (for images), text-model creation/resolver, clipboard image read, host screenshot, dialog service, telemetry (optional).
- Implement widget.attachmentModel.addContext(...) equivalent and serialization for request payloads.

Open questions (for implementation)
- On hosts without a full editor stack, how should we present "Open Editors"? Options: map to recent files, open buffers list, or hide the pick.
- How should omittedState be surfaced to users on attach? Minimal behavior: show a small warning badge on the attachment and allow expansion to preview.

Last reviewed: 2025-08-09T07:59:29Z
