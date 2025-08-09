Attachment model, resolution, chat core, sessions & setup
=========================================================

Summary
-------
This document synthesizes responsibilities, invariants, porting risks and tests for the chat attachment resolution/model, core chat interfaces, sessions UI and the Copilot setup flow.

Primary source files examined:
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chat.ts:1`](src/vs/workbench/contrib/chat/browser/chat.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatSessions.ts:1`](src/vs/workbench/contrib/chat/browser/chatSessions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatSetup.ts:1`](src/vs/workbench/contrib/chat/browser/chatSetup.ts:1)

Responsibilities (high level)
-----------------------------
- Attachment resolution: convert drag/editor/resource/notebook/SCM/marker/symbol payloads into chat attachment entries and normalize image buffers (`ChatAttachmentResolveService`).
- Attachment registry: keep the in-memory set of attachments, expose CRUD and change events (`ChatAttachmentModel`).
- Chat public surface: types & services for widgets, quick chat and codeblock metadata (`chat.ts`).
- Sessions UI: tree-backed sessions view with dynamic provider registration and local session discovery (`chatSessions.ts`).
- Setup & entitlement flow: sign-in, install, entitlements, default setup agents/tools and forwarding requests to Copilot (`chatSetup.ts`).

Important classes / APIs
-----------------------
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:52`](src/vs/workbench/contrib/chat/browser/chatAttachmentResolveService.ts:52) — implements `IChatAttachmentResolveService`:
  - resolveEditorAttachContext, resolveImageAttachContext, resolveNotebookOutputAttachContext, resolveMarkerAttachContext, resolveSymbolsAttachContext, resolveSourceControlHistoryItemAttachContext.
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:26`](src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:26) — `ChatAttachmentModel`:
  - Map keyed by entry.id, addContext/clear/delete/updateContext, `onDidChange` event with deleted/added/updated arrays.
- [`src/vs/workbench/contrib/chat/browser/chat.ts:30`](src/vs/workbench/contrib/chat/browser/chat.ts:30) — public types & services:
  - `IChatWidgetService`, `IChatWidget`, `IQuickChatService`, helpers to show chat views.
- [`src/vs/workbench/contrib/chat/browser/chatSessions.ts:67`](src/vs/workbench/contrib/chat/browser/chatSessions.ts:67) — `ChatSessionsView`, `LocalChatSessionsProvider`, Sessions tree and view registration.
- [`src/vs/workbench/contrib/chat/browser/chatSetup.ts:100`](src/vs/workbench/contrib/chat/browser/chatSetup.ts:100) — `ChatSetup`, `ChatSetupController`, `SetupAgent`:
  - sign-in, install extension, setup dialog, agent/tool registration and forwarding logic.

Injected services & runtime dependencies
---------------------------------------
- Core platform: `IFileService`, `IEditorService`, `ITextModelService`, `IViewDescriptorService`, `IMenuService`, `IContextMenuService`.
- Drag/drop & content: CodeDataTransfers, `ISharedWebContentExtractorService`, `IChatAttachmentResolveService`.
- Extensions & agents: `IExtensionService`, `IChatAgentService`, `ILanguageModelToolsService`, `ILanguageModelsService`.
- UI/UX: `IProgressService`, `IQuickInputService`, `IDialogService`, `ResourceLabels`.
- Auth/telemetry/entitlement: `IAuthenticationService`, `IChatEntitlementService`, `ITelemetryService`.
- Browser APIs: File/Blob/URL.createObjectURL, DataTransfer/File API for drag.

UI and behavior flows
---------------------
- Drag->Resolve->Model->UI:
  - Drag or addFile triggers `ChatAttachmentResolveService.resolve*` → returns `IChatRequestVariableEntry` or entries → `ChatAttachmentModel.addContext(...)` → input UI listens to model and renders AttachmentWidgets.
- Image handling:
  - Files/URLs read into buffers, size cap enforced (30MB), computed id via `imageToHash`, optionally `resizeImage`, UI uses Blob URLs and revokes them on load/error.
- Sessions:
  - `LocalChatSessionsProvider` watches editor groups for `ChatEditorInput` and lists them (maintains order); sessions view registers providers and view descriptors dynamically.
- Setup:
  - `ChatSetup` orchestrates trust prompt, sign-in/signup, extension install (with retries), and replaces `setup.*` placeholder agents/tools with real ones; it forwards pending requests when Copilot is ready.

Lifecycle invariants & patterns
------------------------------
- AttachmentModel:
  - Keys are `entry.id`; addContext ignores duplicates; clear supports sticky prompt-file attachments.
  - updateContext must only emit when something changed and must supply arrays of deleted/added/updated ids/entries.
- ResolveService:
  - Uses `textModelService.createModelReference(resource)` to probe language id and always disposes the reference.
  - Image path reading enforces size cap and throws / shows dialog on too-large images.
- Sessions:
  - Dynamically registers/deregisters view descriptors via Registry; keep registration id stable and avoid double-registration.
- Setup:
  - Long-running flows use `progressService.withProgress`, `ChatSetupController` sends state events; extension install is done with retry/cancellation handling.

Porting & integration notes (risks)
----------------------------------
- Platform coupling: many services (views, menus, extension install, auth, telemetry) — port must provide adapters or thin shims for these.
- Drag/drop payload expectations: code expects rich CodeDataTransfers shapes (editors, markers, symbols, notebook outputs, SCM history). Implement a compatibility layer that maps host drag payloads to those shapes or provide `IChatAttachmentResolveService` with equivalent behavior.
- Image fetching & CORS: `ISharedWebContentExtractorService.readImage` is used to fetch remote images. In non-browser hosts handle CORS or provide server-side fetch/transform.
- Extension install model: `ChatSetup` installs/enables extensions programmatically. On targets without that concept, map to manual install instructions or alternative workflows.
- Entitlement & auth flows: port needs equivalent sign-in/entitlement handling or provide stubs for dev/test environments.
- Memory/resource cleanup: Blob URLs must be revoked; ensure equivalent resource lifecycle for images in the host.

Suggested tests / verification
-----------------------------
- ChatAttachmentResolveService
  - image file: supported extension -> returns image entry (and resized buffer when appropriate).
  - oversized image (>30MB): triggers dialog/error.
  - notebook output: only supported mime types processed.
- ChatAttachmentModel
  - addContext ignores duplicates, clear(false) keeps prompt-file entries, updateContext emits correct arrays.
- ChatSessions
  - LocalChatSessionsProvider maintains ordered list and reacts to group open/close/move events.
  - SessionsViewPane registers/deregisters view descriptors without duplicates.
- ChatSetup
  - sign-in cancellation path, install retry logic, forwarding requests only when agent & language/tools ready.

Actionable porting checklist items
----------------------------------
- Implement adapters for:
  - `IChatAttachmentResolveService` (all resolve APIs) and image resizing/hash helpers.
  - `ISharedWebContentExtractorService.readImage` (or fallback network fetch).
  - Model probing: `ITextModelService.createModelReference` semantics (probe language id + dispose).
  - Views/Menus/Registry APIs used by sessions and setup (dynamic view registration).
  - Authentication/entitlement APIs or a manual/setup flow for agents.
- Preserve invariants:
  - attachment id uniqueness, image size cap, blob revocation, updateContext event semantics.
- Add unit/integration tests per Suggested tests.

Next steps
----------
1. Author a focused contract doc for `IChatAttachmentResolveService` showing input shapes and sample responses.
2. Add test harness snippets to emulate CodeDataTransfers payloads for integration tests.
3. Continue automated loop: read remaining chat UI plumbing files (`chatInputPart.ts`, `chatWidget.ts`, `chatListRenderer.ts`, `chatEditor.ts`, `chatViewPane.ts`), synthesize feature docs and finalize the master manifest / QA pass.

End of document
