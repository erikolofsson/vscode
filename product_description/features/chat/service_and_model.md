# Chat — Service & Data Model (service API, session lifecycle, persistence)

Purpose
- Summarize the Chat service API surface, data model (requests/responses), session lifecycle and persistence shape. These notes focus on porting considerations: what must be preserved, what can be simplified, and tests to validate behavior.

Primary source files
- [`src/vs/workbench/contrib/chat/common/chatService.ts:1`](src/vs/workbench/contrib/chat/common/chatService.ts:1)
- [`src/vs/workbench/contrib/chat/common/chatModel.ts:1`](src/vs/workbench/contrib/chat/common/chatModel.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chat.ts:1`](src/vs/workbench/contrib/chat/browser/chat.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatSessions.ts:1`](src/vs/workbench/contrib/chat/browser/chatSessions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatFollowups.ts:1`](src/vs/workbench/contrib/chat/browser/chatFollowups.ts:1)

High-level responsibilities
- IChatService
  - Orchestration API for sending/resending requests, session creation/lookup and persistence; emits lifecycle events and records user actions. See [`src/vs/workbench/contrib/chat/common/chatService.ts:597`](src/vs/workbench/contrib/chat/common/chatService.ts:597).
  - Key capabilities: sendRequest(), resendRequest(), startSession(), getSession(), transferChatSession(), activateDefaultAgent(), notifyUserAction(), request-in-progress observable and event hooks.
- ChatModel (IChatModel / ChatModel)
  - In-memory session model: ordered ChatRequestModel[] plus session metadata, checkpointing, undo-stop semantics, edit tracking, and serialization to storage. See [`src/vs/workbench/contrib/chat/common/chatModel.ts:1181`](src/vs/workbench/contrib/chat/common/chatModel.ts:1181).
  - Each request is a ChatRequestModel with message (parsed), variableData (attachments/variables), attached context, locationData and a ChatResponseModel (streamed/partial). See [`src/vs/workbench/contrib/chat/common/chatModel.ts:218`](src/vs/workbench/contrib/chat/common/chatModel.ts:218).
  - Responses are modeled as rich sequences of IChatProgress parts (markdownContent, textEditGroup, toolInvocation, inline refs, file trees, etc.)—the Response and ResponseView abstractions manage streaming updates and "view of response" for undo-stop support. See [`src/vs/workbench/contrib/chat/common/chatModel.ts:297`](src/vs/workbench/contrib/chat/common/chatModel.ts:297).
- Chat widget & view layer contracts
  - IChatWidget exposes view-level helpers and integration points (open/focus codeblocks, acceptInput, attachmentModel, viewState). See [`src/vs/workbench/contrib/chat/browser/chat.ts:177`](src/vs/workbench/contrib/chat/browser/chat.ts:177).
  - IChatWidgetService is a lightweight registry for widgets and provides cross-widget operations (find widget by sessionId / inputUri). See [`src/vs/workbench/contrib/chat/browser/chat.ts:30`](src/vs/workbench/contrib/chat/browser/chat.ts:30).
- Sessions UI and providers
  - Sessions can be provided by extension points and local provider (editors + widgets). Session listing UI (ChatSessionsView) coordinates providers and registers container views dynamically. See [`src/vs/workbench/contrib/chat/browser/chatSessions.ts:56`](src/vs/workbench/contrib/chat/browser/chatSessions.ts:56).
- Followups UI
  - Small helper to render followup suggestion buttons; depends on agent metadata for tooltip/composition. See [`src/vs/workbench/contrib/chat/browser/chatFollowups.ts:18`](src/vs/workbench/contrib/chat/browser/chatFollowups.ts:18).

Important data shapes and semantics
- IChatProgress union drives rendering and persisted history. Preserve the shape for any features that rely on replay: markdownContent, textEditGroup, toolInvocation, codeblockUri, treeData, etc. See [`src/vs/workbench/contrib/chat/common/chatService.ts:354`](src/vs/workbench/contrib/chat/common/chatService.ts:354).
- Undo-stop model:
  - Responses can insert undo stops (IChatUndoStop) to mark boundaries where later content can be excluded from certain operations (e.g., checkpointing / send removal). The ResponseView slices content up to an undo stop. See [`src/vs/workbench/contrib/chat/common/chatModel.ts:425`](src/vs/workbench/contrib/chat/common/chatModel.ts:425).
- Checkpointing:
  - ChatModel.setCheckpoint disables (hides/blocks) requests/responses after a checkpoint. This is important for workflows that hide prior context when reusing requests. See [`src/vs/workbench/contrib/chat/common/chatModel.ts:1466`](src/vs/workbench/contrib/chat/common/chatModel.ts:1466).
- Text-edit groups and apply semantics:
  - Text edits are assembled into IChatTextEditGroup or IChatNotebookEditGroup entries in responses. The model records state (sha1/applied count) and UI uses these to drive apply/discard flows. See [`src/vs/workbench/contrib/chat/common/chatModel.ts:70`](src/vs/workbench/contrib/chat/common/chatModel.ts:70).

Key flows (short)
- sendRequest(sessionId, message, options)
  - IChatService.sendRequest returns a pair of promises: responseCreated and responseComplete (IChatSendRequestResponseState). The service appends a request model to the session model and then streams response progress parts which the model accepts (ChatModel.acceptResponseProgress). See [`src/vs/workbench/contrib/chat/common/chatService.ts:617`](src/vs/workbench/contrib/chat/common/chatService.ts:617).
- Streaming updates
  - Responses arrive as incremental IChatProgress parts and are appended to ChatResponseModel via ChatModel.acceptResponseProgress. The renderer uses parts to compute progressive renders and height updates. See [`src/vs/workbench/contrib/chat/common/chatModel.ts:1587`](src/vs/workbench/contrib/chat/common/chatModel.ts:1587).
- Resend / adopt / transfer
  - Requests may be resent or adopted between sessions (move to another editor widget). ChatModel.adoptRequest and IChatService.transferChatSession support those operations, including appropriate model event emission. See [`src/vs/workbench/contrib/chat/common/chatModel.ts:1568`](src/vs/workbench/contrib/chat/common/chatModel.ts:1568) and [`src/vs/workbench/contrib/chat/common/chatService.ts:636`](src/vs/workbench/contrib/chat/common/chatService.ts:636).

Platform & porting considerations
- Preserve progressive/streaming model
  - The service + model split assumes streaming granular updates that the UI diffs. If porting to a platform where streaming isn't available, emulate via chunked updates, but preserve ordering and undo-stop semantics (so checkpointing & partial application still work). See [`src/vs/workbench/contrib/chat/common/chatModel.ts:329`](src/vs/workbench/contrib/chat/common/chatModel.ts:329).
- Storage format & migrations
  - ChatModel includes backward-compatible normalization and multiple serialized versions (ISerializableChatData1..3). Ported implementations should provide similar versioned serialization & migration when saving sessions. See [`src/vs/workbench/contrib/chat/common/chatModel.ts:1007`](src/vs/workbench/contrib/chat/common/chatModel.ts:1007).
- Complexity around many progress kinds
  - The model supports many progress kinds (tools, attachments, diffs). If your port ignores some kinds (e.g., notebook edits, code citations), document these as unsupported and ensure graceful handling (no crashes) when encountering them. See full list in [`src/vs/workbench/contrib/chat/common/chatService.ts:354`](src/vs/workbench/contrib/chat/common/chatService.ts:354).
- Event model and observables
  - The upstream code uses observables (IObservable/ITransaction) for state like requestInProgress and isPaused. Provide equivalent reactive primitives or wrap with simple events/boolean flags.
- Editor/inline chat session mapping
  - Sessions can be attached to editor inputs and widgets (see ChatSessions local provider). If your target UI has different editor concepts, map sessions to appropriate resources and provide session discovery provider hooks analogous to the extension point used in [`src/vs/workbench/contrib/chat/browser/chatSessions.ts:419`](src/vs/workbench/contrib/chat/browser/chatSessions.ts:419).
- Security: resource URIs
  - Chat responses may include embedded resources (ChatResponseResource scheme). Preserve a mapping/handler for resource URIs and a safe way to resolve/serve them. See [`src/vs/workbench/contrib/chat/common/chatModel.ts:1808`](src/vs/workbench/contrib/chat/common/chatModel.ts:1808).

Testing checklist (service & model)
- Unit tests
  - ChatModel serialization roundtrip (versions 1..3) and normalization. Exercise revive paths (see [`src/vs/workbench/contrib/chat/common/chatModel.ts:1032`](src/vs/workbench/contrib/chat/common/chatModel.ts:1032)).
  - Progressive content merging for markdown parts (canMergeMarkdownStrings / appendMarkdownString). See [`src/vs/workbench/contrib/chat/common/chatModel.ts:1754`](src/vs/workbench/contrib/chat/common/chatModel.ts:1754).
  - Undo-stop / ResponseView slicing behavior: ensure ResponseView hides post-undo-stop content.
  - Checkpoint semantics: setCheckpoint hides/disables expected requests/responses.
  - TextEditGroup state updates (sha1/applied) and response.setEditApplied() behavior.
- Integration tests
  - sendRequest streaming path: service appends request, streams parts, UI receives onDidChange events and model reflects complete response.
  - Resend/adopt flow: request moved between sessions preserving ids and response state.
  - Persistence test: create session, serialize to disk, reload and ensure model equivalence (requests/responses/followups).
- Manual / E2E
  - Verify followups rendering & click paths (see [`src/vs/workbench/contrib/chat/browser/chatFollowups.ts:40`](src/vs/workbench/contrib/chat/browser/chatFollowups.ts:40)).
  - Session discovery: open editor-backed sessions and ensure ChatSessions view lists them in expected order (see [`src/vs/workbench/contrib/chat/browser/chatSessions.ts:311`](src/vs/workbench/contrib/chat/browser/chatSessions.ts:311)).

Minimal porting checklist (service + model)
- [ ] Implement IChatService facade (sendRequest/resend/transfer/activateDefaultAgent + events).
- [ ] Implement an in-memory ChatModel with:
  - request/response model, response streaming parts, undo-stop and checkpoint support.
- [ ] Provide serialization with versioned migration hooks.
- [ ] Provide a mechanism for session providers (local & extension-like contributions) and a sessions UI that lists them.
- [ ] Provide resource handler for embedded response resources (ChatResponseResource scheme).
- [ ] Provide observability hooks for requestInProgress, isPaused and pending confirmations.
- [ ] Implement tests: unit (model edge cases), integration (send/stream/resend), persistence (roundtrip).

Cross-references & recommended next reading
- Service API overview: [`src/vs/workbench/contrib/chat/common/chatService.ts:597`](src/vs/workbench/contrib/chat/common/chatService.ts:597)
- Model internals & serialization: [`src/vs/workbench/contrib/chat/common/chatModel.ts:1181`](src/vs/workbench/contrib/chat/common/chatModel.ts:1181)
- Widget contracts / view helpers: [`src/vs/workbench/contrib/chat/browser/chat.ts:177`](src/vs/workbench/contrib/chat/browser/chat.ts:177)
- Sessions UI & provider pattern: [`src/vs/workbench/contrib/chat/browser/chatSessions.ts:330`](src/vs/workbench/contrib/chat/browser/chatSessions.ts:330)
- Followups rendering: [`src/vs/workbench/contrib/chat/browser/chatFollowups.ts:18`](src/vs/workbench/contrib/chat/browser/chatFollowups.ts:18)

End of document.
