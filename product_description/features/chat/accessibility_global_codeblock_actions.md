# Chat — Accessibility, Global Actions & Code-block Operations

Summary:
This doc synthesizes accessibility help providers, global chat actions (open/toggle/history/clear), title/footer actions, and code-block toolbar/command actions.

Source files (primary)
- [`src/vs/workbench/contrib/chat/browser/actions/chatAccessibilityHelp.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatAccessibilityHelp.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatClear.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatClear.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatTitleActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatTitleActions.ts:1)

Responsibilities
- Provide accessible help and aria-friendly guidance for multiple chat surfaces (panel, quick, inline, edits, agent).
- Register global commands and menu items to open/toggle chat, show history, manage settings, and clear workspace chat state.
- Title/footer actions for per-response interactions: vote, retry, report, insert into notebook.
- Code-block actions: copy, apply in-editor, insert at cursor, insert into new file, run in terminal, compare/apply/discard edits.

Accessibility & help
- The accessible view providers are implemented via [`getChatAccessibilityHelpProvider()`](src/vs/workbench/contrib/chat/browser/actions/chatAccessibilityHelp.ts:132) and registered per-surface (`panelChat`, `quickChat`, `editsView`, `agentView`, `inlineChat`).
- Help text generation is centralized in [`getAccessibilityHelpText()`](src/vs/workbench/contrib/chat/browser/actions/chatAccessibilityHelp.ts:65); it resolves keybinding labels using the platform keybinding service to produce spoken labels and hints.
- The provider ties to an input editor DOM node and restores focus when the accessible view is closed; it also selects verbosity via accessibility settings.
- Porting note: platforms without AccessibleView must provide an alternate aria-live/announcement path and a static help overlay with keybinding hints.

Global & title actions
- Opening and mode-aware initialization uses [`OpenChatGlobalAction.run()`](src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:137) which accepts `IChatViewOpenOptions` to prefill query, attach files/screenshots, or set mode.
- Mode switching includes guard logic via [`handleModeSwitch()`](src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:1424) which may prompt to clear an editing session; confirmation flow uses [`handleCurrentEditingSession()`](src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:1413).
- History UI (legacy and integrated pickers) uses quick-pick fast/slow flows and AsyncIterable consumption for coding agent sessions (see history picker in [`registerChatActions()`](src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:283)).
- Clear/replace editor flow uses [`clearChatEditor()`](src/vs/workbench/contrib/chat/browser/actions/chatClear.ts:11) to replace an open ChatEditorInput with a new pinned editor URI.

Code-block actions & behavior
- Toolbar/menu actions for code blocks are registered under `MenuId.ChatCodeBlock`; rendering helpers are registered by [`CodeBlockActionRendering`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:91).
- Supported actions:
  - Copy code block: [`workbench.action.chat.copyCodeBlock`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:128) — records telemetry via chatService.notifyUserAction.
  - Apply in editor: [`workbench.action.chat.applyInEditor`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:245) — delegates to `ApplyCodeBlockOperation`.
  - Insert at cursor / into new file: [`workbench.action.chat.insertCodeBlock`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:288) and [`workbench.action.chat.insertIntoNewFile`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:324).
  - Run in terminal: [`workbench.action.chat.runInTerminal`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:376) — considers terminal stdin availability and target location.
- Copy integration: the editor global copy command is extended to support copying full code-block cells when no selection is present (see `CopyAction.addImplementation` hook in [`chatCodeblockActions.ts:180`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:180)).

Edit & compare actions
- Compare-block actions allow applying or discarding individual edit hunks via `applyCompareEdits` and `discardCompareEdits` handlers (`registerChatCodeCompareBlockActions()` in [`chatCodeblockActions.ts:563`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:563)).
- Review/edit application uses `reviewEdits` and AsyncIterable text edit streams to progressively render and apply edits; this is fragile across hosts that lack bulk-edit or notebook APIs.

Lifecycles & telemetry
- Most user-facing actions call `chatService.notifyUserAction(...)` to surface telemetry and extension callbacks (see multiple notify calls across `chatCodeblockActions.ts` and `chatTitleActions.ts`).
- Actions are guarded by `ChatContextKeys` context expressions to control enablement and menu visibility.

Porting risks & mitigations
- AccessibleView dependency: provide an aria-live fallback or static help panel when `AccessibleView` is not available.
- QuickPick / AsyncIterable patterns: hosts without AsyncIterable support should allow buffered slow picks or synchronous fallbacks to avoid UI blocking.
- Editor model & bulk edits: `reviewEdits`, `IBulkEditService`, and notebook APIs are required for apply/insert flows; if absent, implement simplified flows (open new file, present unified diff, or copy to clipboard).
- Terminal integration: ensure terminal API exposes runCommand and focus behavior; otherwise offer "copy-to-terminal" and instruct user.
- ContextKey system: replicate or approximate context predicates to keep action visibility sensible.

Tests & QA suggestions
- Unit tests:
  - Accessibility help: verify `getAccessibilityHelpText()` renders expected phrases and binds keybinding labels correctly.
  - Code-block actions: ensure `CopyAction` hook copies full cell with no selection, and `notifyUserAction` payload shapes are correct.
  - Clear editor replacement: mock `IEditorService` to verify `clearChatEditor()` replaces a `ChatEditorInput` with `ChatEditorInput.getNewEditorUri()`.
- Integration tests:
  - History picker fast/slow flow: simulate cached history + async coding agent sessions and verify picker updates progressively.
  - Apply-in-editor flow: run `ApplyCodeBlockOperation` with AsyncIterable edits and mock `reviewEdits()` to assert applied edits and editor reveal behavior.

Cross-links
- Context/picker and execute actions: [`product_description/features/chat/context_and_execute_and_copy_actions.md:1`](product_description/features/chat/context_and_execute_and_copy_actions.md:1)
- File-tree, title & clear actions: [`product_description/features/chat/filetree_title_clear_actions.md:1`](product_description/features/chat/filetree_title_clear_actions.md:1)
- Code block operations (implementation): [`src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:1`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:1)

Last reviewed: 2025-08-09T08:04:37Z
