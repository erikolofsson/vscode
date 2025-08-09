# Chat — File Tree Navigation, Title Actions & Clear/New Chat

Summary:
This feature doc covers file-tree navigation within responses, title/footer actions (votes, retry, report, insert into notebook), and clear/new-chat flows.

Source files (primary)
- [`src/vs/workbench/contrib/chat/browser/actions/chatFileTreeActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatFileTreeActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatCopyActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatCopyActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatTitleActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatTitleActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatClearActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatClearActions.ts:1)

Responsibilities
- Keyboard-driven navigation across file-trees attached to a response, cycling forward/backward.
- Title/footer actions per response: vote up/down, report issue, retry, insert into notebook.
- New chat and clear flows that reset editing sessions, attachments, and focus, with accessibility announcements.
- Undo/redo and checkpoint/restore flows tied into editing sessions and confirmation dialogs.

File-tree navigation behavior
- Triggered by commands: NextFileTree / PreviousFileTree (keybindings F9 variants).
- Navigation finds the current or last response, reveals it, queries responseFileTrees and lastFocusedFileTree, computes next focus index, and focuses that tree.
- Focus semantics: if editor input is focused, navigation uses widget.getFocus and isResponseVM checks to find response to operate on.

Title/footer actions behavior
- Helpful / Unhelpful: set vote state on response VM and call chatService.notifyUserAction with vote metadata.
- Unhelpful may accept a reason (ChatAgentVoteDownReason) and records it on the response VM.
- Report Issue: sends a 'bug' user action to chatService.notifyUserAction.
- Retry: resend the request via chatService.resendRequest. If in Edit/Agent modes and edits were made, prompts user to confirm undo/restore and optionally updates configuration to skip future prompts.
- Insert into Notebook: splits markdown and code blocks and applies bulk notebook cell edits via IBulkEditService.

Clear / New Chat / Edit session flows
- NewChatAction / NewChatEditorAction and ACTION_ID_NEW_CHAT:
  - call handleCurrentEditingSession(...) to confirm/cleanup current edits.
  - stop editing session, clear widget, waitForReady, clear attachments and related files, focus input.
  - preserve optional initial inputValue/agentMode/isPartialQuery to prefill or dispatch a request.
- Accessibility: announceChatCleared plays AccessibilitySignal.clear via IAccessibilitySignalService.
- Undo/Redo/RedoCheckpoint: editing-session specific actions call editingSession.undoInteraction(), redoInteraction(), and restore snapshots. RedoCheckpoint replays all redo operations and clears checkpoint when done.

Lifecycles & call-sites
- Actions are registered via registerAction2 at activation time for the chat contribution.
- File-tree navigation relies on widget.getFileTreeInfosForResponse() and lastFocused metadata stored on the widget.
- Title actions operate on IChatResponseViewModel and mutate response VM state and communicate with IChatService.
- New chat/clear interacts with IChatEditingService and ChatEditorInput (ChatEditorInput.getNewEditorUri() elsewhere) to create fresh editors.

Porting risks & fragilities
- Keybinding and ContextKeyExpr: visibility and bindings depend on platform context key system; fallback strategies required where not available.
- Notebook bulk edits: IBulkEditService and notebook editor APIs may be missing on target hosts; provide a fallback like opening a new editor with the response content.
- Accessibility signals: platforms lacking AccessibilitySignalService must still ensure a11y notification (announce via aria-live region).
- Editing-session snapshot/restore semantics rely on a consistent persistent model; if unavailable, retries/undos must be surfaced differently to users (warning + safe no-op).
- File-tree focus model assumes response-level file trees; ports may need to emulate file-tree widgets or provide a simplified file list focus API.

Recommended mitigations
- Implement a thin context-key abstraction that can be satisfied or defaulted on simpler hosts.
- For notebooks, if IBulkEditService is absent, provide "Copy to clipboard" or "Open new file" alternatives.
- Expose a small accessibility adapter that maps playSignal to an aria-live update when AccessibilitySignalService is missing.
- Log and gracefully handle missing dependencies during actions instead of throwing; surface minimal user-facing messages.

Tests & QA
- Unit tests:
  - navigateTrees behavior: given mock file-tree arrays and lastFocused index, compute next index correctly for forward and reverse.
  - MarkHelpful / MarkUnhelpful: response VM vote state changes and chatService.notifyUserAction call.
  - NewChatAction: ensure editingSession.stop() called, attachments cleared, input focused, and inputValue acceptance behavior.
- Integration tests:
  - Retry path with editing-session modifications: confirm dialog flow and snapshot restore occurs, followed by resendRequest call.
  - Insert into Notebook: splitting markdown/code blocks and bulk edit application on a real notebook model.
- Manual checks:
  - Keyboard cycle through file-trees, verify focus moves and responds to reverse/forward bindings.
  - Accessibility announcement when creating new chat.

Cross-links
- See context and execute actions doc: [`product_description/features/chat/context_and_execute_and_copy_actions.md:1`](product_description/features/chat/context_and_execute_and_copy_actions.md:1)
- See codeblock and apply/insert doc: [`src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:1`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:1)
- See attachments & widget internals: [`product_description/features/chat/attachments_widget_and_editor.md:1`](product_description/features/chat/attachments_widget_and_editor.md:1)

Last reviewed: 2025-08-09T08:03:02Z
