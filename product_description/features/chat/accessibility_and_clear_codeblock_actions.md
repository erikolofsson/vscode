Accessibility, Global Actions, Clear Flows & Code-block Actions

Summary:
This doc synthesizes responsibilities, call-sites, lifecycles, porting risks and test proposals for accessibility help, global chat actions, clear/new-chat flows, and code-block actions.

Source files:
- [`src/vs/workbench/contrib/chat/browser/actions/chatAccessibilityHelp.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatAccessibilityHelp.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatClear.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatClear.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatClearActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatClearActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:1)

Responsibilities:
- Accessibility providers and help text: the panel/quick/edits/agent providers surface high-verbosity, keybinding-aware help for screen-readers and accessible views. See [`PanelChatAccessibilityHelp`](src/vs/workbench/contrib/chat/browser/actions/chatAccessibilityHelp.ts:21).
- Global open/toggle and mode switch: Open/toggle actions open the chat view, switch modes, attach files/screenshots, and optionally run a prefilled query. See [`OpenChatGlobalAction`](src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:123).
- Clear / New Chat / Edit sessions: flows carefully coordinate editingSession lifecycle, confirmation prompts, and clearing UI state. Core replacement of a chat editor is performed by [`clearChatEditor`](src/vs/workbench/contrib/chat/browser/actions/chatClear.ts:11) and the new-session action is [`NewChatAction`](src/vs/workbench/contrib/chat/browser/actions/chatClearActions.ts:67).
- Code-block actions: copy, insert, apply, run-in-terminal and compare-block operations wire into editor/notebook/terminal APIs and notify telemetry/user-action endpoints. High-level operations implemented in [`InsertCodeBlockOperation`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:40) and [`ApplyCodeBlockOperation`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:114).

Call-sites & integrations:
- Accessibility help provider obtains the focused/input editor and generates help text with resolved keybinding labels via [`getChatAccessibilityHelpProvider`](src/vs/workbench/contrib/chat/browser/actions/chatAccessibilityHelp.ts:132).
- Apply/Insert flows call into the code-mapper provider (`ICodeMapperService.mapCode`) and consume edits as an AsyncIterable, then call `reviewEdits`/`reviewNotebookEdits` for inline preview before commit. See [`ApplyCodeBlockOperation.run`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:132).
- UI context for code-block actions is derived from focused editors or external providers: [`getContextFromEditor`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:532).
- New chat and mode switching use `handleCurrentEditingSession` / `handleModeSwitch` to surface confirmation and determine whether to clear the existing session: see [`handleCurrentEditingSession`](src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:1413).

Lifecycle & state details:
- New chat / clear: the workflow announces accessibility signals, stops the editing session, clears attachments and relatedFiles, and either resets the editor input or replaces the chat editor via `editorService.replaceEditors`. See [`clearChatEditor`](src/vs/workbench/contrib/chat/browser/actions/chatClear.ts:11) and the new-chat action in [`chatClearActions.ts:44`](src/vs/workbench/contrib/chat/browser/actions/chatClearActions.ts:44).
- Apply flow: evaluates an optional codemapper URI, prompts the user to create/open/choose the target (via QuickPick), opens the target editor if necessary, streams edits (AsyncIterable), offers inline review, and only then applies edits. See `evaluateURIToUse` and the apply handlers in [`codeBlockOperations.ts`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:187,160).
- Cancellation: mapping requests are cancellable via a CancellationTokenSource wired to the progress notification; errors due to cancellation are ignored to avoid noisy dialogs. See [`codeBlockOperations.ts:246`].

Key utilities & algorithms:
- Reindent logic: `reindent` adapts pasted code indentation to the target model's formatting options using `computeIndentation`. See [`reindent`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:455) and [`computeIndentation`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:493).
- Start-on-first-element streaming helper: `waitForFirstElement` converts an AsyncIterable into another iterable that only yields after the first element is available to avoid races between progress UI and producer. See [`waitForFirstElement`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:356).

Porting risks & mitigations:
- Accessibility: the accessible view + keybinding-label resolution is tightly coupled to platform keybinding APIs. Port: provide a fallback static help overlay and resolve host key labels as best-effort.
- AsyncIterable streaming & code-mapper contracts: ports may lack AsyncIterable producer/consumer patterns. Port: buffer provider emissions and expose a Promise/array fallback; keep progress cancellation semantics.
- Inline review & editor integration: `reviewEdits`/`reviewNotebookEdits` and notebook `insertCell` rely on host editor features. Port: if unavailable, fallback to presenting a diff patch in a modal and require explicit user confirmation.
- Terminal & notebook differences: run-in-terminal and notebook insert APIs may need adaption — fallback to opening a shell buffer or an untitled editor with the code block.
- Error handling: some code paths rethrow or log; prefer explicit IDialogService-driven user messages on ports.

Tests to add:
- Unit: `computeIndentation` and `reindent` with a matrix of tabs/spaces/mixed/empty-line cases.
- Unit: `evaluateURIToUse` with (existing resource, createFile success/failure, untitled fallback).
- Integration: mocked `ICodeMapperService` streaming multi-chunk edits; assert progress UI shows, inline preview invoked, and final edits applied or cancelled.
- E2E: New Chat action clears editing sessions and preserves/clears attachments and selection as expected.

Cross-links:
- Actions & Tool Picker: [`product_description/features/chat/actions_and_tool_picker.md:1`](product_description/features/chat/actions_and_tool_picker.md:1)
- Transfer & Codeblocks: [`product_description/features/chat/transfer_codeblocks_toolpicker.md:1`](product_description/features/chat/transfer_codeblocks_toolpicker.md:1)
