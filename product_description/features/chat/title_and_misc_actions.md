# Chat title, clear, accessibility, developer & file-tree actions

Overview

This document synthesizes responsibilities, call-sites, UI flows and porting notes for chat title/footer actions (vote/report/retry/insert-into-notebook), clear/new-chat flows, accessibility help providers, developer logging actions, and file-tree navigation actions.

Primary source files
- [`src/vs/workbench/contrib/chat/browser/actions/chatClear.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatClear.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatAccessibilityHelp.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatAccessibilityHelp.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatDeveloperActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatDeveloperActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatFileTreeActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatFileTreeActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatTitleActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatTitleActions.ts:1)

Responsibilities

- Clear / New Chat
  - Replace existing ChatEditorInput with a fresh editor instance and orchestrate widget clear/attachment reset. See [`clearChatEditor`](src/vs/workbench/contrib/chat/browser/actions/chatClear.ts:11).
  - Editing-session checks and confirmation flows are handled elsewhere and invoked by the new chat actions; accessibility signals are emitted on clear.

- Accessibility help
  - Register AccessibleView help providers for Panel, Quick, Edits and Agent contexts that return descriptive help text and provide a focus callback. These providers use keybinding lookup to include current shortcuts in the help text. See [`getChatAccessibilityHelpProvider`](src/vs/workbench/contrib/chat/browser/actions/chatAccessibilityHelp.ts:132).

- Developer actions
  - Lightweight developer utilities to log widget input history and the chat index. These are categorized under developer actions and are safe to omit in a port but useful for debugging. See [`registerChatDeveloperActions`](src/vs/workbench/contrib/chat/browser/actions/chatDeveloperActions.ts:15).

- File-tree navigation
  - Commands to navigate file-tree widgets attached to a response (Next/Previous File Tree). Navigation uses widget.getFileTreeInfosForResponse and focus bookkeeping; wraps across boundaries. See [`navigateTrees`](src/vs/workbench/contrib/chat/browser/actions/chatFileTreeActions.ts:60).

- Title/footer actions
  - Vote (helpful / unhelpful) and reporting actions that call IChatService.notifyUserAction and update UI state on the response VM.
  - Retry action with edit-session-aware confirmation logic; may restore snapshots before resending a request.
  - Insert into Notebook: splits response markdown into markdown/code cells (uses marked lexer), then applies ResourceNotebookCellEdit via IBulkEditService. See [`splitMarkdownAndCodeBlocks`](src/vs/workbench/contrib/chat/browser/actions/chatTitleActions.ts:357).

Key behaviors & flows

- Clearing chat:
  - `clearChatEditor` replaces the ChatEditorInput with a new ChatEditorInput uri (using EditorService.replaceEditors), preserving group placement (`chatClear.ts:11`).

- Accessibility help:
  - Providers compute help text with localized strings and included keybinding labels (calls keybindingService.lookupKeybindings). They return an AccessibleContentProvider that can restore focus to the input editor after the help view is closed (`chatAccessibilityHelp.ts:132`).

- Feedback & retry:
  - MarkHelpful / MarkUnhelpful update response VM state and call into IChatService.notifyUserAction to surface telemetry/extension events (`chatTitleActions.ts:33`).
  - Retry will optionally prompt the user if retrying would undo edits in the current editing session; it restores snapshots and resends using chatService.resendRequest (`chatTitleActions.ts:176`).

- Insert into Notebook:
  - Parse response into blocks via a markdown lexer, then create notebook cells using bulk edit cell replacement. This expects a notebook host and bulk edit support (`chatTitleActions.ts:271`).

Notable implementation details

- Editor operations:
  - Replacing chat editor instances uses EditorService.replaceEditors and ChatEditorInput.getNewEditorUri (`chatClear.ts:11`).
- Accessibility:
  - AccessibleView providers include verbosity settings and use getChatAccessibilityHelpText to assemble localized help strings (`chatAccessibilityHelp.ts:65`).
- Markdown parsing:
  - `splitMarkdownAndCodeBlocks` uses `marked` to lex markdown and emit code blocks vs markdown blocks for insertion into notebooks (`chatTitleActions.ts:357`).

Porting risks & fragilities

- Editor / workbench APIs
  - Actions rely on EditorService, BulkEditService and Notebook APIs (ResourceNotebookCellEdit). Ports without an editor host or notebooks must provide shims or disable notebook insertion.
- Accessibility subsystem
  - AccessibleView and verbosity settings are used to present help. Ports lacking these should provide a no-op help or a simplified help modal.
- Keybinding lookup semantics
  - Help text includes aria-friendly keybinding labels; missing keybinding lookup will reduce usefulness. Provide a lookup fallback or static labeling.
- Chat model/time-travel semantics
  - Retry flow manipulates editing-session snapshots; port must preserve editing session semantics or simplify the retry UX to avoid data loss.
- Menu/context system
  - Menu visibility depends on ChatContextKeys and many when expressions. Port must expose a contextkey system or map simpler visibility rules.

Recommended tests

- Unit:
  - splitMarkdownAndCodeBlocks: test markdown with mixed code fences and inline markdown.
  - clearChatEditor: ensure replacement uses EditorService.replaceEditors and the new editor uri is created.

- Integration:
  - Accessibility provider: ensure help text contains keybinding labels when keybindings exist.
  - Retry flow: simulate editing session with modified entries and confirm prompt behavior, snapshot restore and resend.

- E2E:
  - Insert into notebook: response -> insert into notebook -> notebook shows expected sequence of markdown/code cells.
  - Voting/reporting: ensure IChatService.notifyUserAction called and VM state updated.

Implementation adapter checklist for porting

1. EditorService adapter: implement replaceEditors, openEditor, findEditors and activeEditorPane semantics.
2. AccessibleView or help modal: provide accessible help content and a way to restore focus to the input editor.
3. Keybinding lookup: provide lookupKeybindings to produce human-readable labels for help text.
4. Bulk edits / Notebook adapter: implement ResourceNotebookCellEdit or provide a fallback to open a new notebook file and write content.
5. ChatContextKeys and menu system: implement context keys to control menu visibility or simplify menus.
6. IChatService.notifyUserAction shim: maintain telemetry/event hooks or provide a safe stub.

Call-sites & registrations

- All actions are registered through registerAction2 in the respective files and wired into menus:
  - ChatMessageFooter, ViewTitle, Editor/Inline widget menus and the inline-chat secondary menu are used by these actions.

Cross-links

- Code-block apply/insert operations and reindent behavior: [`src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:1`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:1)
- Attachment / context pickers: [`src/vs/workbench/contrib/chat/browser/actions/chatContext.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatContext.ts:1)
- Widget & session interfaces: [`src/vs/workbench/contrib/chat/browser/chat.ts:1`](src/vs/workbench/contrib/chat/browser/chat.ts:1)

Short actionable TODOs

- Add unit tests for `splitMarkdownAndCodeBlocks`.
- Add a PORTING_CHECKLIST entry noting AccessibleView and notebook bulk-edit dependencies.
- Add a fallback implementation note for Insert into Notebook if notebook APIs are not available.

Document prepared from:
- [`src/vs/workbench/contrib/chat/browser/actions/chatClear.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatClear.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatAccessibilityHelp.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatAccessibilityHelp.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatDeveloperActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatDeveloperActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatFileTreeActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatFileTreeActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatTitleActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatTitleActions.ts:1)
