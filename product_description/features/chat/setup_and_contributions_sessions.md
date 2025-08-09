# Chat: Contributions, Setup, Sessions, and Status

Summary

This doc synthesizes responsibilities, registrations, contribution points, setup/entitlement flow, sessions view, and status bar for the Chat subsystem.

Files read and synthesized
- [`src/vs/workbench/contrib/chat/browser/chat.contribution.ts:1`](src/vs/workbench/contrib/chat/browser/chat.contribution.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chat.ts:1`](src/vs/workbench/contrib/chat/browser/chat.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatSessions.ts:1`](src/vs/workbench/contrib/chat/browser/chatSessions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatSetup.ts:1`](src/vs/workbench/contrib/chat/browser/chatSetup.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatStatus.ts:1`](src/vs/workbench/contrib/chat/browser/chatStatus.ts:1)

High-level responsibilities
- Registering services/singletons, editor input factories, contribution points, actions and configuration.
- Handling entitlement, setup, installation and extension activation flows.
- Providing the Chat Sessions view and local session provider (editor-based sessions and panel widget).
- Orchestrating setup agents and "forward to Copilot" logic for requests when Copilot is unavailable.
- Status bar entry, quota display and settings UI for Copilot/chat entitlement.

Key registrations & contribution points
- Configuration: registers chat-related settings under `chatSidebar` and many `chat.*` keys. See [`src/vs/workbench/contrib/chat/browser/chat.contribution.ts:1`](src/vs/workbench/contrib/chat/browser/chat.contribution.ts:1).
- Editor Pane: registers ChatEditor and ChatEditorInput serializer and resolver (editor factory/serializer registration). See registry calls in [`src/vs/workbench/contrib/chat/browser/chat.contribution.ts:1`](src/vs/workbench/contrib/chat/browser/chat.contribution.ts:1).
- Extension points: `chatOutputRenderers` extension point with activation events `onChatOutputRenderer:<viewType>` used by output renderers (see related output renderer service).
- Service singletons: IChatService, IChatWidgetService, IChatOutputRendererService and related language/model services are registered as delayed singletons. See registration block in [`src/vs/workbench/contrib/chat/browser/chat.contribution.ts:1`](src/vs/workbench/contrib/chat/browser/chat.contribution.ts:1).
- Workbench contributions: ChatSetupContribution, ChatSessionsView, ChatStatusBarEntry and others are registered with WorkbenchPhase ordering for startup/restore. See registrations in [`src/vs/workbench/contrib/chat/browser/chat.contribution.ts:1`](src/vs/workbench/contrib/chat/browser/chat.contribution.ts:1).

Setup & entitlement flow (summary)
- ChatSetupContribution wires ChatSetupController and ChatSetup. It coordinates signing in, installing the Copilot extension, handling enterprise/provider options, and telemetry around setup. See [`src/vs/workbench/contrib/chat/browser/chatSetup.ts:1`](src/vs/workbench/contrib/chat/browser/chatSetup.ts:1).
- ChatSetup exposes commands (CHAT_SETUP_ACTION_ID and variants) that can be triggered from UI, accounts, or URLs (extension URL handler).
- SetupStrategy: multiple paths (default, enterprise, social providers, canceled). The flow includes workspace trust checks, optional sign-in, sign-up flows, extension installation, and retry/telemetry on failure.
- SetupAgent: a thin agent that forwards requests to Copilot when the local agent is missing. It waits for language models, tools, and agent readiness before re-sending requests.
- Important invariants: installation should be non-blocking; forward-to-Copilot should avoid duplicate forwarding and surface clear progress/warnings.

Sessions & UI
- ChatSessions.ts implements a Chat Sessions viewlet:
  - LocalChatSessionsProvider: tracks open ChatEditorInput instances and panel chat widget instances; preserves ordering and maps to editor groups.
  - ChatSessionsViewPaneContainer: registers per-provider views (local + contributed session providers) under VIEWLET_ID and manages dynamic view registration.
  - Sessions tree uses WorkbenchAsyncDataTree with custom renderers and delegates; interactions open editors or reveal widget instances.
- Session URIs: ChatSessionUri.forSession is used to open editor inputs for contributed sessions.
- Important behavior: provider-based registration (extensions can contribute providers); view registration/unregistration is dynamic and must be handled carefully during port.

Status & telemetry
- ChatStatus.ts provides a status bar entry (Copilot icon), telemetry events for actions, quota and entitlement displays, and a dashboard tooltip. It consumes ChatEntitlementService for quota information and entitlements.
- The dashboard is interactive: quota indicators, upgrade/manage links, settings toggles, and a completions "snooze" control; contributions can add status entries.

Public APIs & services used by other subsystems
- IChatService, IChatWidgetService, IChatOutputRendererService: core services used across widget, content parts, and editor pieces.
- IChatAgentService / ChatAgentService: agent registration/slash commands integrate with setup and runtime behavior.
- ILanguageModelsService and ILanguageModelToolsService: setup waits for models/tools readiness before forwarding requests.
- IExtensionsWorkbenchService: used to programmatically install the Copilot extension.

Call sites & interactions
- chatWidget, input parts, output renderers and codeBlock parts depend on services registered here. See orchestration in [`src/vs/workbench/contrib/chat/browser/chatWidget.ts:1`](src/vs/workbench/contrib/chat/browser/chatWidget.ts:1).
- ChatSetup forwards requests using chatService.resendRequest when Copilot becomes available and uses progress messages to keep the user informed.

Porting risks & fragilities
- Entitlement & setup model is heavy: relies on platform authentication, extension install APIs, and telemetry hooks. Ports must provide equivalents or replace flows with simplified UX.
- Programmatic extension installation via IExtensionsWorkbenchService may not exist in target environments; provide manual install alternatives or document limitations.
- ChatSessions dynamic view registration relies on ViewsRegistry APIs — ports need equivalent view lifecycle or pre-baked session UI.
- Telemetry & policy hooks (PolicyTag-based configuration) must be adapted or stubbed.
- ChatSetup expects workspace trust and authentication session APIs; these must be mapped or gracefully degraded.

Tests to add / verify during port
- Setup flow tests: simulate entitlements Unknown/Free/Pro and verify proper setup paths, enterprise/provider handling, and telemetry.
- Forward-to-Copilot integration: simulate Copilot unavailability then availability; assert request resend and progress/warning messages are shown.
- Sessions provider tests: open/close ChatEditorInput across groups and assert LocalChatSessionsProvider ordering and view registration.
- Status dashboard tests: verify quota indicators, links, snooze behavior and updates on entitlement changes.

Concrete porting checklist (prioritized)
1. Provide equivalents for IExtensionsWorkbenchService.install or document manual install alternative for Copilot-like dependencies.
2. Implement or stub entitlement/auth/session APIs used by ChatSetup/ChatEntitlementService.
3. Provide a ViewsRegistry-like mechanism or pre-register Chat Sessions UI; ensure provider-based registration can be modeled.
4. Implement ChatStatus dashboard components (quota, upgrade links, settings toggles) or provide simplified status replacement.
5. Recreate command registrations & action wiring (CHAT_SETUP_ACTION_ID and variants) or expose simplified commands for setup.
6. Preserve telemetry hooks where possible or stub them to avoid runtime errors.
7. Verify integration with language model services and tools; ensure ChatSetup wait/ready logic can query equivalent model/tool readiness.

Implementation notes & suggestions
- Keep setup logic idempotent and non-blocking; use background installation where possible and surface progress to the user.
- Favor clear failure messages and graceful fallbacks when entitlement/auth or extension-install APIs are absent.
- For platforms without dynamic view registration, implement a single Sessions UI that lists local sessions and contributed sessions (if any).
- Centralize provider IDs, command IDs and configuration keys in a small mapping module to reduce mismatch risk.

Next steps (automated loop)
- Add this doc to MANIFEST and OVERVIEW cross-links.
- Continue reading next prioritized batch: files related to tools, language model tools contributions, and chat actions under src/vs/workbench/contrib/chat/browser/actions and tools/.
- After finishing batches, perform QA pass linking all feature docs and finalize product_description/MANIFEST.md.

References
- [`src/vs/workbench/contrib/chat/browser/chat.contribution.ts:1`](src/vs/workbench/contrib/chat/browser/chat.contribution.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chat.ts:1`](src/vs/workbench/contrib/chat/browser/chat.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatSessions.ts:1`](src/vs/workbench/contrib/chat/browser/chatSessions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatSetup.ts:1`](src/vs/workbench/contrib/chat/browser/chatSetup.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatStatus.ts:1`](src/vs/workbench/contrib/chat/browser/chatStatus.ts:1)
