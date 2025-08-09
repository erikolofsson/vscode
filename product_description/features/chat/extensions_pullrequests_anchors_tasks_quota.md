Chat: Extensions, Markdown Anchors, Pull Requests, Quota & Tasks

Summary
This document summarizes responsibilities, UI flows, lifecycle patterns, injected services and porting considerations for the following chat content parts and supporting service.

Key files
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatExtensionsContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatExtensionsContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownAnchorService.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownAnchorService.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatPullRequestContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatPullRequestContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatQuotaExceededPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatQuotaExceededPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTaskContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTaskContentPart.ts:1)

Responsibilities (per-component)
- Extensions content: render a paged, interactive ExtensionsList, show loading placeholder, and signal size changes once populated.
- Markdown anchor service: track InlineAnchorWidget instances, expose the last focused anchor, and manage focus/blur listeners lifecycle.
- Pull request content: render PR metadata (title, link, author, description) and open PR URI via IOpenerService on click.
- Quota exceeded part: render entitlement-specific calls-to-action, telemetry and command wiring, and surface retry/wait warnings driven by module-level state.
- Task content: render either a collapsible progress list (when task.progress present) or a progress spinner/content part (for unsettled streaming tasks).

Injected services & runtime dependencies
- Instantiation service (create ExtensionsList, ChatCollapsibleListContentPart, ChatProgressContentPart).
- IExtensionsWorkbenchService used to resolve extension details for the ExtensionsList.
- IOpenerService for opening PR URIs.
- IChatWidgetService for rerunLastRequest wiring in quota retry flow.
- ICommandService and ITelemetryService used by quota actions to execute commands and record telemetry.
- MarkdownRenderer used by quota and task parts to render text safely.

UI flows
- ExtensionsList: show loading placeholder, async populate via getExtensions(), remove placeholder, set PagedModel on list, call list.layout() and emit height change.
- Pull request: display PR card with clickable link; click handler prevents default and uses openerService.open(uri).
- Quota exceeded: initial rendering depends on current entitlement; primary button triggers different command IDs; after clicking, show retry button and wait-warning according to module-level flags; retry calls widget.rerunLastRequest().
- Task: if progress entries exist render a collapsible list of references; otherwise render ChatProgressContentPart and show spinner if not settled and request in flight.

Lifecycle patterns & implementation contracts
- ChatMarkdownAnchorService.register: stores widget in internal list, uses addDisposableListener for focus/blur and returns a combinedDisposable to unregister listeners and remove widget entry.
- QuotaExceededPart uses module-level boolean flags to persist UI state across instances: the flags control whether retry and wait-warning appear across multiple renderings.
- ChatTaskContentPart branches rendering based on whether task.progress has entries and whether task is settled; it forwards onDidChangeHeight from nested parts when rendering collapsible lists.

Porting considerations & risks
- ExtensionsList integration: host must implement an equivalent list widget and PagedModel semantics; ensure layout() and onDidChangeHeight signaling are available.
- Anchor focus semantics: rely on isActiveElement and DOM focus/blur events; on platforms with different focus handling or virtual DOM, map equivalents and ensure InlineAnchorWidget exposes getHTMLElement().
- Module-level UI state in quota widget: the persistent booleans reduce statefulness requirements but create global cross-instance behavior—evaluate whether this is acceptable or should be moved to a session-scoped store in the new host.
- Command/telemetry wiring: quota buttons invoke commands via ICommandService and log telemetry via ITelemetryService; port must implement compatible command routing and telemetry APIs.
- Markdown rendering: ensure the host's MarkdownRenderer or equivalent applies the same sanitizer and rendering options used by VS Code to avoid XSS or visual regressions.

Test ideas and verification
- Unit: ChatMarkdownAnchorService.register should register focus/blur listeners, update lastFocusedAnchor correctly and throw when registering same widget twice.
- Integration/UI: ExtensionsList population test: simulate getExtensions resolving and verify placeholder removed, model set, list.layout called, and onDidChangeHeight fired.
- Quota flows: simulate different entitlement values, click primary button, verify command executed and telemetry emitted, and verify retry and wait-warning toggles appear after interactions.
- Task rendering: verify path when task.progress is present uses the CollapsibleListContentPart and for streaming tasks the spinner and ChatProgressContentPart are rendered and height events wired.

Verbatim patterns to preserve in port
- The use of combinedDisposable and addDisposableListener for anchor registration lifecycle management.
- Module-level persistent flags driving UI changes across instances (the retry / wait-warning booleans).
- The exact branching logic in ChatTaskContentPart that chooses between CollapsibleListContentPart vs ChatProgressContentPart.

Accessibility notes
- Anchor widgets are tracked by focus/blur; ensure ARIA attributes and keyboard focusability are preserved for InlineAnchorWidget in the port.

Porting checklist entries
- Implement host adapter for ExtensionsList and PagedModel semantics.
- Provide an InlineAnchorWidget equivalent and map focus detection APIs.
- Mirror ICommandService and ITelemetryService command/telemetry calls for quota actions.
- Ensure MarkdownRenderer compatibility and safe HTML sanitization settings.

Related documents and next steps
- See other chat docs for overlapping concerns (code blocks, tool invocation, webview output sizing).
- Next automated step: continue with the next prioritized batch of chat content parts and produce a follow-up feature doc.
