# Chat — Elicitation, Errors & Confirmation Widgets (batch)

Summary of batch read (files)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatElicitationContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatElicitationContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationWidget.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationWidget.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorConfirmationPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorConfirmationPart.ts:1)

Responsibilities
- Elicitation prompts and accept/reject lifecycle: [`ChatElicitationContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatElicitationContentPart.ts:16)
- Error rendering and severity badge/ui: [`ChatErrorContentPart` / `ChatErrorWidget`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorContentPart.ts:18)
- Confirmation flows and sendRequest integration: [`ChatConfirmationContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationContentPart.ts:17)
- Reusable confirmation UI and title/message/button rendering: [`ChatConfirmationWidget`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationWidget.ts:228)
- Error-specific confirmation buttons for remediation flows: [`ChatErrorConfirmationContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorConfirmationPart.ts:22)

Injected services & dependencies
- Instantiation service and chat accessibility used by elicitation: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatElicitationContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatElicitationContentPart.ts:1)
- MarkdownRenderer for error/confirmation message rendering: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorContentPart.ts:1)
- IChatService, IChatWidgetService and command/sendRequest wiring used by confirmation parts: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationContentPart.ts:1)
- Host / Views / Notification / Opener integration for window notifications and links: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationWidget.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationWidget.ts:1)

UI flows & interactions
- Elicitation: constructs a [`ChatConfirmationWidget`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatElicitationContentPart.ts:34), shows accept/reject buttons when pending, awaits accept()/reject() and then hides buttons and updates message (see [`chatElicitationContentPart.ts:34`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatElicitationContentPart.ts:34)).
- Confirmation: user clicks a confirmation button → build IChatSendRequestOptions (agentId, slashCommand, confirmation, model/mode options) → call `chatService.sendRequest(...)` → on success mark confirmation used and hide buttons (see [`chatConfirmationContentPart.ts:47`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationContentPart.ts:47)).
- Confirmation widget behavior: renders title/subtitle/message, supports dropdown/more actions, fires onDidChangeHeight when async content renders, and notifies the host window when needed (`notifyConfirmationNeeded`) to surface OS-level notifications (see [`chatConfirmationWidget.ts:135`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationWidget.ts:135)).
- Error confirmation: renders error UI plus remediation buttons; clicks map to sendRequest with accepted/rejected confirmation data (see [`chatErrorConfirmationPart.ts:49`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorConfirmationPart.ts:49)).

Lifecycle & patterns
- All parts and widgets follow IDisposable patterns and register disposables via this._register to ensure proper cleanup.
- Confirmation widgets use MutableDisposable/DisposableStore to manage temporary notifications and hover/tool lifecycle.
- Elicitation explicitly calls the accessibility service to announce and register the elicitation for SR users (`chatElicitationContentPart.ts:57`).

Porting considerations & risks
- Notifications & focus: `ChatConfirmationWidget.notifyConfirmationNeeded` uses host focus APIs and platform notifications — target platform must support focusing windows and showing notifications or provide safe shims (`chatConfirmationWidget.ts:198`).
- Markdown rendering & link handling: message rendering relies on `MarkdownRenderer` and `openLinkFromMarkdown` for link actions — sanitize and hook into opener service correctly (`chatConfirmationWidget.ts:48` and `chatErrorContentPart.ts:66`).
- Asynchronous sendRequest semantics: confirmation flows await `chatService.sendRequest()` and then update UI — port must preserve that contract and error handling.
- Accessibility: ensure aria-label, tabindex and screen-reader-friendly announcements (elicitation calls `chatAccessibilityService.acceptElicitation`) are replicated.
- Race conditions: confirmation visibility toggles and notification lifecycle must be robust to rapid focus/visibility changes.

Suggested tests
- Elicitation flow test: verify construction of `ChatConfirmationWidget`, accept/reject invoke underlying accept()/reject() and UI updates (buttons hidden).
- Confirmation sendRequest test: mock `chatService.sendRequest` to return success/failure and assert options passed (agentId, slashCommand, confirmation, model/mode).
- Notification behavior test: simulate unfocused window and assert that host focus and triggerNotification are invoked and that clicking notification focuses the chat view.
- Error widget rendering test: render `ChatErrorContentPart` for each `ChatErrorLevel` and assert icon, text and markdown output.

Next automated actions
1. Add this doc into the feature docset (this file).
2. Mark this batch completed in the TODO.
3. Continue with the next prioritized batch of chatContentParts / toolInvocationParts (5 files).

End.
