Chat: Collapsible UI, Collections, Commands & Confirmations

Summary
This document captures responsibilities, UI flows, lifecycle patterns, injected services and porting considerations for collapsible UI parts, resource pools, command buttons and confirmation widgets in the chat subsystem.

Key files
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatCodeCitationContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatCodeCitationContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatCollapsibleContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatCollapsibleContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatCollections.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatCollections.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatCommandContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatCommandContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationContentPart.ts:1)

Responsibilities (per-component)
- Code citation: render a compact message with a "View matches" button that opens a new editor with a generated markdown document and logs telemetry.
- Collapsible content: provide a reusable collapsible header with accessible label, icon and an observable expanded state; fire height-change events on DOM connection and expand/collapse.
- Collections / ResourcePool: provide pooled reusable UI objects (editors, trees, lists) with get() / release() semantics and inUse tracking.
- Command button: render a command button that respects restored-response disablement and executes ICommandService with provided arguments.
- Confirmation widget: instantiate ChatConfirmationWidget, map button clicks to chatService.sendRequest with constructed IChatSendRequestOptions, hide buttons when confirmation becomes used and forward height-change events.

Injected services & dependencies
- Editor and telemetry: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatCodeCitationContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatCodeCitationContentPart.ts:1) uses IEditorService and ITelemetryService.
- Instantiation, chat and widget services: ChatConfirmationContentPart depends on IInstantiationService, IChatService and IChatWidgetService to create widgets and send requests.
- Command service: ChatCommandButtonContentPart uses ICommandService to execute commands.
- Reactive primitives: observableValue, autorun are used by collapsible parts and must be provided or adapted in the host.

UI flows & interactions
- Code citations: click "View matches" → open in-editor contents (markdown) via IEditorService.openEditor(...) → telemetry publicLog2 emitted.
- Collapsible: clicking the ButtonWithIcon toggles observable expanded state; autorun updates icon (chevronRight/chevronDown), toggles collapsed CSS class, updates ariaLabel, and queues a microtask to fire onDidChangeHeight if element is connected.
- ResourcePool: consumers call get() and release(item) — when creating new items the pool registers disposables with the pool owner (this._register), and release pushes item back to pool and removes from inUse.
- Command button: enabled unless element is a restored response (isResponseVM && element.isStale) — click executes command id and arguments via ICommandService.
- Confirmation: confirmationWidget.onDidClick → construct prompt and options (accepted/rejected confirmation data, agentId, slashCommand, userSelectedModelId, mode, getModeRequestOptions) → chatService.sendRequest(sessionId, prompt, options) → on success mark confirmation.isUsed and hide buttons.

Lifecycle patterns & contracts
- Collapsible lazy init: domNode is created on first access via init(); autorun lifecycle tied to Disposable for cleanup.
- Collapsible state: uses observableValue<boolean> for expanded state; expanded observable exposed to callers.
- ResourcePool lifecycle: pool holds created items, _register(item) ensures pool disposes items when pool disposed; inUse set tracks active instances.
- Confirmation forwarding: ChatConfirmationContentPart wires confirmationWidget.onDidChangeHeight to its own onDidChangeHeight and updates widget visibility based on confirmation.isUsed.

Porting considerations & risks
- Reactive system: autorun/observableValue pattern must be mapped to host reactive primitives or shimmed; losing microtask-on-connected semantics may break incremental layout updates.
- Disposal semantics: ResourcePool.register uses this._register(this._itemFactory()) — ensure pool-owner disposal semantics are preserved so pooled items are cleaned up correctly.
- Accessibility: updateAriaLabel must be preserved exactly to keep screen-reader friendly expanded/collapsed messages.
- Restored chat semantics: isResponseVM + element.isStale gating for command buttons must be replicated to avoid enabling actions on stale/restored responses.
- Confirmation options and model selection: ChatConfirmationContentPart reads widget.getModeRequestOptions() and widget.input.currentLanguageModel — host must expose equivalent mode selection and option plumbing.

Tests and verification
- Unit: ResourcePool.get() and release() correctness; inUse set updated; pooled items are disposed when pool disposed.
- Unit: Collapsible autorun toggles icon and ariaLabel and queueMicrotask triggers onDidChangeHeight when connected.
- Integration: ChatCommandButtonContentPart executes ICommandService.executeCommand with correct id and arguments and respects disabled state for restored responses.
- Integration/UI: ChatConfirmationContentPart constructs and sends chatService.sendRequest with expected options and hides buttons on success.

Verbatim patterns to preserve
- ResourcePool pattern:
  - get() { if (pool.length > 0) { item = pool.pop(); _inUse.add(item); return item; } item = this._register(this._itemFactory()); _inUse.add(item); return item; }
  - release(item) { _inUse.delete(item); pool.push(item); }
- Collapsible autorun snippet:
  - const value = this._isExpanded.read(r);
  - collapseButton.icon = value ? Codicon.chevronDown : Codicon.chevronRight;
  - queueMicrotask(() => { this._onDidChangeHeight.fire(); });
- Confirmation send flow:
  - Build options: acceptedConfirmationData / rejectedConfirmationData, agentId, slashCommand, userSelectedModelId, mode, Object.assign(options, widget?.getModeRequestOptions());
  - if (await chatService.sendRequest(...)) { confirmation.isUsed = true; confirmationWidget.setShowButtons(false); this._onDidChangeHeight.fire(); }

Accessibility notes
- Preserve ariaLabel updates from updateAriaLabel() and keyboard operability for ButtonWithIcon and ChatConfirmationWidget.

Next steps
- Continue with the next prioritized batch of five files, synthesize notes and author the next feature doc.
