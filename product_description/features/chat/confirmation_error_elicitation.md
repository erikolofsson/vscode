# Chat — Confirmation, Errors & Elicitation

Summary of batch read (files)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationWidget.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationWidget.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorConfirmationPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorConfirmationPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatElicitationContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatElicitationContentPart.ts:1)

Responsibilities
- Confirmation prompts rendering, wiring accept/dismiss to chatService.sendRequest, and hiding UI after acceptance. (see [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationContentPart.ts:1))
- Confirmation widget composition, title rendering, button behaviors, notification and focus UX when confirmation needed. (see [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationWidget.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationWidget.ts:1))
- Error presentation (info/warning/error) and simple markup rendering. (see [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorContentPart.ts:1))
- Error-level confirmations with specialized buttons that call sendRequest and update UI based on response. (see [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorConfirmationPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorConfirmationPart.ts:1))
- Elicitation (asking for user approval/input) with accept/reject flows, accessibility notification and button wiring. (see [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatElicitationContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatElicitationContentPart.ts:1))

Injected services & dependencies
- IInstantiationService to create widgets and subparts.
- IChatService and IChatWidgetService for sendRequest wiring and to obtain widget state (modelId, mode, etc.).
- MarkdownRenderer, IOpenerService, host/view services for notifications and link handling in titles.
- Configuration, context menu and host services for focus/notification preferences.

UI flows & interactions
- Confirmation flow: render ChatConfirmationWidget, show buttons unless previously used, clicking a button builds IChatSendRequestOptions (agentId, slashCommand, userSelectedModelId, mode) and calls chatService.sendRequest(sessionId, prompt, options). On success, hide buttons and update part height. (see [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationContentPart.ts:1))
- Notification: if chat view not focused and config 'chat.notifyWindowOnConfirmation' true, ChatConfirmationWidget triggers a host focus/notification with action to show chat view. (see [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationWidget.ts:198`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationWidget.ts:198))
- Error flows: ChatErrorWidget shows severity icon + rendered markdown. Error confirmations render buttons that call sendRequest similarly to confirmation flows. (see [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorConfirmationPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorConfirmationPart.ts:1))
- Elicitation: specialized confirmation with accept/reject that calls elicitation.accept()/reject(), updates message with acceptedResult when present, and notifies accessibility service. (see [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatElicitationContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatElicitationContentPart.ts:1))

Patterns & lifecycle
- Widgets expose onDidChangeHeight; parent parts listen and re-layout as needed.
- ChatConfirmationWidget extends a base that manages button rendering, button disabling via Event bindings, and optional dropdown actions via ButtonWithDropdown.
- ChatConfirmationWidget may produce a notification disposable to focus/reveal chat UI; ensure disposal on focus change.

Porting considerations & risks
- host notification/focus APIs: ChatConfirmationWidget uses IHostService and dom.triggerNotification to notify and focus; port must provide similar capabilities or adjust UX (high risk for desktop vs web environments).
- sendRequest options assembly: code reads widget input state (currentLanguageModel, mode, getModeRequestOptions) — host must expose equivalent to capture user's context in confirmation requests.
- Markdown rendering & link handling: ChatQueryTitlePart leverages MarkdownRenderer and openLinkFromMarkdown — ensure renderer & opener integration preserves trusted links and async rendering callbacks.
- Accessibility: elicitation and progress use aria labels and call IChatAccessibilityService.acceptElicitation; preserve SR announcements and focus behavior.

Suggested tests
- Confirmation sendRequest: mock chatService.sendRequest and chatWidgetService to verify correct options are constructed and buttons hide on success.
- Notification behavior: mock host focus and notification to assert a notification is created when chat view not focused and config enabled; clicking notification invokes showChatView.
- Error confirmation: assert confirmation buttons call sendRequest with correct accepted/rejected payload and on success update UI.
- Elicitation accept/reject: assert elicitation.accept/reject invoked and message updated when acceptedResult present.

Next automated actions
1. Write this synthesized note into product_description/features/chat/ (this file)
2. Update TODO to mark this batch completed
3. Continue with next prioritized batch (I will list remaining files and proceed)

Implementation notes for engineers
- Keep ChatConfirmationWidget's notification disposable properly disposed when focus returns to avoid leaks.
- When testing, stub widget.getModeRequestOptions and currentLanguageModel to provide deterministic sendRequest options.
- Preserve exact aria strings used where possible for accessibility testing.

End of file.
