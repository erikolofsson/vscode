# Chat — Setup, Participants, Status & Paste Providers

Purpose
- Consolidated notes from implementation files covering setup/entitlement, participants extension point, statusbar & dashboard, output renderers, and paste/image attachment providers.

Related source files (representative)
- [`src/vs/workbench/contrib/chat/browser/chatSetup.ts:1`](src/vs/workbench/contrib/chat/browser/chatSetup.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatParticipant.contribution.ts:1`](src/vs/workbench/contrib/chat/browser/chatParticipant.contribution.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatStatus.ts:1`](src/vs/workbench/contrib/chat/browser/chatStatus.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:1`](src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:1)

High-level responsibilities
- Setup and entitlement flows: sign-in, extension install, provider configuration and telemetry.
- Register built-in agents/tools for "setup" experience and forward requests to provider agents when available.
- Expose UI actions/commands for setup and related flows.
- Register chat participant extension point and wire contributed participants into IChatAgentService.
- Provide statusbar entry & dashboard summarizing quota, settings, and actions (snooze, manage).
- Provide output renderer host for third-party renderers via webviews.
- Provide paste providers for images, copied code, and attachments that translate clipboard content into chat attachment variables.

Setup & entitlement (details)
- The ChatSetup flow is centered on [`ChatSetup.getInstance()`](src/vs/workbench/contrib/chat/browser/chatSetup.ts:591) and [`ChatSetupController`](src/vs/workbench/contrib/chat/browser/chatSetup.ts:1163).
- Key behaviors:
  - Request workspace trust before proceeding ([`ChatSetup.run()`](src/vs/workbench/contrib/chat/browser/chatSetup.ts:625)).
  - Sign-in flow (via `requests.signIn`) and optional enterprise/provider configuration ([`ChatSetupController.signIn()`](src/vs/workbench/contrib/chat/browser/chatSetup.ts:1279)).
  - Install the provider extension with retries (`extensionsWorkbenchService.install`) and telemetry around installResult/duration ([`ChatSetup.doInstall()`](src/vs/workbench/contrib/chat/browser/chatSetup.ts:1386)).
  - After successful setup, the flow may mutate the request model to replace "setup." agent/tool parts with real agents/tools (see [`SetupAgent.replaceAgentInRequestModel()`](src/vs/workbench/contrib/chat/browser/chatSetup.ts:452) and [`replaceToolInRequestModel()`](src/vs/workbench/contrib/chat/browser/chatSetup.ts:487)).
- Setup exposes actions/commands: [`CHAT_SETUP_ACTION_ID` / chat setup commands`](src/vs/workbench/contrib/chat/browser/chatSetup.ts:66) and registers UI dialogs for sign-in and provider selection.

Forwarding & lazy readiness
- When a "setup" agent receives a request, it waits for three readiness signals before forwarding:
  - agent registration readiness (extensions registering default agents),
  - language model availability (`ILanguageModelsService`),
  - tools model registration (`ILanguageModelToolsService`).
- If readiness times out, the code logs a warning and emits an unresolvable event to clear registrations (see [`SetupAgent.doForwardRequestToCopilotWhenReady()`](src/vs/workbench/contrib/chat/browser/chatSetup.ts:273)).

Participants / Extension point
- The extension point `chatParticipants` is declared in [`chatParticipant.contribution.ts`](src/vs/workbench/contrib/chat/browser/chatParticipant.contribution.ts:83). Contributions can declare:
  - id, name, fullName, description, commands (slash-commands), disambiguation, modes, locations, and when-clauses.
- The handler registers participants into `IChatAgentService` and keeps a DisposableMap to unregister on extension removal (`ChatExtensionPointHandler.handleAndRegisterChatExtensions()`).
- The contribution enforces validation: name regex, ambiguous/invisible characters checks, and proposed API gating for advanced fields.

Statusbar & Dashboard
- `ChatStatusBarEntry` provides a statusbar entry and lazy `ChatStatusDashboard` rendering (see [`chatStatus.ts:106`](src/vs/workbench/contrib/chat/browser/chatStatus.ts:106)).
- Dashboard responsibilities:
  - Render quota indicators (chat/completions/premium), reset date, and "Upgrade" actions.
  - Render contributed status items from `IChatStatusItemService`.
  - Provide settings toggles and "snooze" control for inline completions and next-edit suggestions.
- Key UI behaviors:
  - Uses live updates and disposables to keep quota information current (`chatEntitlementService.update()`).
  - Exposes telemetry for setting changes and actions (e.g., 'chatStatus.settingChanged').

Output renderers & webview hosting
- Third-party extensions can register chat output renderers via the `chatOutputRenderers` extension point. The host service is [`ChatOutputRendererService`](src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:61).
- Flow:
  - `renderOutputPart(mime, data, parent, options, token)` resolves the appropriate renderer (activates matching extension), creates a webview with WebviewContentPurpose.ChatOutputItem, and mounts it into the parent DOM node before delegating to the renderer implementation.
  - The service wires an autorun to observe intrinsic webview content size and emit onDidChangeHeight (used by the chat renderer to update virtualization).

Paste / Clipboard providers
- Multiple DocumentPasteEditProviders are registered for `Schemas.vscodeChatInput` and global sources in [`ChatPasteProvidersFeature`](src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:433).
- Providers:
  - `PasteImageProvider` — detects image/* clipboard items when the proposed API `chatReferenceBinaryData` is enabled, writes image files into workspace storage, resizes images, computes SHA-256 hash (`imageToHash`) and produces an IChatRequestVariableEntry with kind 'image' (see [`getImageAttachContext()`](src/vs/workbench/contrib/chat/browser/chatPasteProviders.ts:134)).
  - `PasteTextProvider` — handles pastes that include a special copy mime created by editor copy provider; converts single-line copied code into a code "paste" attachment with metadata and references.
  - `CopyAttachmentsProvider` — serializes attachments + dynamic variables into a custom mime and supports paste undo/redo via additionalEdit metadata.
  - `CopyTextProvider` — places a custom `application/vnd.code.additional-editor-data` entry into dataTransfer on copy to enable richer paste semantics.
- Paste flow notes:
  - Providers create DocumentPasteEdit sessions with an empty insertText and an additionalEdit that mutates ChatWidget.attachmentModel (undo/redo support).
  - Many checks ensure provider activation only for chat input buffers (model.uri.scheme === Schemas.vscodeChatInput) and deduplicate by comparing existing attachment IDs.

Security & storage considerations
- Images are written to `workspaceStorageHome/vscode-chat-images` and cleaned up periodically (`cleanupOldImages`).
- Paste providers and output renderers use proposed APIs gating — porting requires equivalent extension gating or a plugin API to allow external renderers to register mime handlers.

Telemetry & UX
- Setup flow logs telemetry events (`commandCenter.chatInstall`) with installResult/installDuration and sign-up error codes.
- Status dashboard logs setting changes and action events. Setup actions log via `workbenchActionExecuted`.

Porting checklist (minimal)
- [ ] Provide an Install/Setup flow that can:
  - request workspace trust,
  - guide sign-in and provider selection,
  - install/enable a provider extension or remote service and report telemetry.
- [ ] Implement an extension/participant registration mechanism mapping contributed participants to agent/service entries.
- [ ] Implement a Statusbar entry + rich dashboard with quota display and settings toggles.
- [ ] Provide a webview-style host/container that safely mounts third-party renderers and reports intrinsic height changes.
- [ ] Implement clipboard/paste providers capable of:
  - extracting binary image data and storing it securely,
  - producing attachment variable entries and composing undo/redo edits.
- [ ] Gate external renderer/paste behaviors behind explicit extension APIs or capability flags.

Testing matrix (suggestions)
- Unit:
  - ChatSetupController flows (sign-in, install, provider selection).
  - Paste providers: image hash computation, deduplication, file creation.
  - ChatOutputRendererService: contribution lookup & activation logic.
- Integration:
  - End-to-end "setup" user flow: sign-in -> install -> forward request -> response from provider.
  - Paste & attach image integration: clipboard -> saved file -> attachment model -> undo/redo.
- Accessibility:
  - Ensure status dashboard controls are keyboard-focusable and have ARIA labels.

Cross-references
- See also: [`product_description/features/chat/overview.md:1`](product_description/features/chat/overview.md:1), [`product_description/features/chat/accessibility.md:1`](product_description/features/chat/accessibility.md:1), [`product_description/features/chat/rendering.md:1`](product_description/features/chat/rendering.md:1).

Notes & open questions
- The setup flow is closely tied to the product's Copilot provider config (product.defaultChatAgent). Porting requires replacing product-specific URLs & CLI commands.
- The paste/image handling uses crypto.subtle.digest (browser) for SHA computation — ensure target runtime supports required crypto primitives or provide fallback.

-- end --
