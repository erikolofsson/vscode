# Chat clear, copy, context & code-block operations

Summary
This doc captures responsibilities, call-sites, UI flows and porting notes for: clearing chat / new chat flows, copy actions, chat context picker (attachments / related files / clipboard images / screenshots), and code-block apply/insert operations.

Primary source files
- [`src/vs/workbench/contrib/chat/browser/actions/chatClearActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatClearActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatCopyActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatCopyActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatContext.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatContext.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:1`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:1)

Responsibilities
- Clear / New Chat:
  - New chat and new edit-session flows, including editing-session checks and confirmations.
  - Accessibility announcements when clearing (IAccessibilitySignalService).
  - Undo/redo of edit interactions and checkpoint handling.
  - Entry points: [`registerNewChatActions()`](src/vs/workbench/contrib/chat/browser/actions/chatClearActions.ts:44).

- Copy actions:
  - Copy full session, individual item copy, and clipboard-aware copy when selection exists inside the widget.
  - Copy telemetry/user-notification hooks via IClipboardService.
  - Entry points: [`registerChatCopyActions()`](src/vs/workbench/contrib/chat/browser/actions/chatCopyActions.ts:16).

- Chat Context / Attachments:
  - Registering context pick items (tools, instructions, open editors, related files, clipboard images, screenshots).
  - Picker plumbing that composes items from multiple providers (IChatContextPickService) and shows QuickPick/QuickAccess UI.
  - Attach flows convert picks into attachment model entries (IChatRequestVariableEntry, file/image/tool attachments).
  - Key classes: [`ChatContextContributions`](src/vs/workbench/contrib/chat/browser/actions/chatContext.ts:34) and [`AttachContextAction`](src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:389).

- Code-block operations:
  - Insert code block at cursor or notebook; reindent to match target editor indentation (InsertCodeBlockOperation).
  - Apply code block: compute edits via CodeMapperService, present inline preview (reviewEdits/reviewNotebookEdits), support choosing target URI (create file / untitled / active editor).
  - Use of AsyncIterable streams for progressive mapper responses and progress UI.
  - Key classes: [`InsertCodeBlockOperation`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:40) and [`ApplyCodeBlockOperation`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:114).

Key objects & injected services used
- Widget & model:
  - IChatWidget, IChatWidgetService — obtain widget, model, attachmentModel and input editor.
- UI / Quick input:
  - IQuickInputService, QuickAccess providers, IQuickPick and IQuickTree where used by other modules.
- Editor / text model:
  - IEditorService, ICodeEditorService, ITextModelService, ITextFileService — open editors, create model references, check readonly flags, compute reindent.
- File / clipboard / host:
  - IFileService, IClipboardService, IHostService — reading files, images, screenshots.
- Code mapping / bulk edits:
  - ICodeMapperService — maps code blocks to TextEdits or notebook edits.
  - IBulkEditService — apply edits to files.
  - reviewEdits / reviewNotebookEdits — inline preview flows.
- Telemetry / logging / dialogs:
  - IChatService.notifyUserAction, ILogService, IDialogService, IProgressService.

UI flows and behaviors (high level)
- Clear / New Chat:
  - New chat actions check current editing session via handleCurrentEditingSession and may prompt; then stop editingSession, clear widget, clear attachments, focus input and optionally seed input or submit immediately. See [`NewChatAction`](src/vs/workbench/contrib/chat/browser/actions/chatClearActions.ts:67).

- Copy:
  - Copy All reads viewModel.getItems(), filters out filtered responses, serializes via stringifyItem and writes to clipboard. Copy Item either uses native selection (if focus is inside widget) or serializes the focused item. See [`CopyAllAction` / `CopyItemAction`](src/vs/workbench/contrib/chat/browser/actions/chatCopyActions.ts:17).

- Attach Context:
  - AttachContextAction builds additionPicks from registered IChatContextPickService items and launches QuickAccess. Picks may be value picks (immediate attachment) or picker picks (sub-pickers). Sub-pickers can be async and return multiple attachments. See [`AttachContextAction._show()`](src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:448).

- Codeblock Insert / Apply:
  - Insert: determine active editable editor or notebook; reindent and apply via bulk edit or insert cell. Notify chat service about the action.
  - Apply: attempt to evaluate codemapperUri; if missing prompt user to choose (create file / untitled / active editor); call codeMapperService.mapCode which yields edits via AsyncIterable; capture first element and show inline preview; finally notify chat service of the result (edits proposed, codeMapper name). See [`ApplyCodeBlockOperation.run()`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:132).

Call-sites & registrations
- Action registration happens via registerAction2 functions in the read files. Attach actions are registered by registerChatContextActions which registers multiple attach flows and prompt actions. See [`registerChatContextActions()`](src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:53).
- Copy / clear actions are wired into ChatContext menus and ViewTitle menus (see menu definitions in the files above).

Porting risks & fragilities
- Model pinning & text model references:
  - Context picker attempts to create text model references (textModelService.createModelReference) to validate attachment readability; ports must implement model-resolver semantics or accept degraded behavior (see [`chatContextActions.ts:517`](src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:517)).

- Async code-mapper and streaming edits:
  - Apply flow relies on AsyncIterable streaming from codeMapperService and the ability to present the first set of edits quickly and then continue streaming. Ports need to support async streaming or convert to a request/response bulk model; otherwise user experience and inline preview will degrade.

- Editor API parity:
  - Insert/Apply operations use bulk edits, editor focus/selection APIs, notebook cell insertion, and logic to detect readonly states via TextFileService. Ports lacking notebook or bulk edit service need alternative edit application implementations.

- Progress & cancellation UX:
  - Progress via IProgressService (cancellable) and CancellationTokenSource are used to allow user cancel. Port must provide equivalent progress & cancel UI to avoid hangs.

- Attachment image handling:
  - Clipboard image read, resizing and hashing are used. Non-browser hosts or restricted environments may need alternate implementations or feature flags.

- ContextPick service extensibility:
  - The platform expects external features to register IChatContextPickService items. Ports must provide an extension/contribution registry or simplify to core picks only.

- Security / size considerations:
  - Attaching large files or screenshots should respect upload limits; the original platform may stream/resize images (resizeImage). Ensure memory/IO constraints are handled.

Recommended tests
- Unit:
  - stringifyItem serialization correctness for request/response VMs.
  - computeIndentation and reindent behavior with tabSize variations.
  - Picker item conversion to attachment entries (tool -> IChatRequestToolEntry, file -> IChatRequestVariableEntry).

- Integration:
  - InsertCodeBlockOperation applies edits to text editor and notebook; test both branches.
  - ApplyCodeBlockOperation: when codeMapper returns edits, inline preview is shown and editsProposed is true; test cancellation path.
  - AttachContextAction -> sub-picker flow: value picks and picker picks produce expected attachments.

- E2E:
  - Full flow: attach file/image -> accept in widget -> submit request including attachments.
  - New chat / clear flows with editing session in-progress prompt correctness and accessibility announcement emission.

Implementation adapter checklist for porting
1. TextModel resolver adapter:
   - Provide createModelReference(uri) to verify file readability and preserve reference lifetimes when editors open transient models.
2. QuickAccess / QuickPick / QuickTree:
   - Provide a quick input abstraction to render pickers and nested pickers (sub-pickers) or a simplified modal picker.
3. Editor & Notebook adapters:
   - Provide code editor selection/focus APIs, bulk-edit application API (or implement edits via file write + reopen), and basic notebook cell insertion if notebooks are supported.
4. CodeMapper streaming API:
   - Implement an ICodeMapperService equivalent or replace with a synchronous mapping endpoint that returns full TextEdits; if streaming is required, provide AsyncIterable support.
5. Clipboard & Image resize:
   - Provide readImage, readClipboard buffer, imageToHash and resizeImage equivalents.
6. Progress & cancellation:
   - Provide a progress UI with cancellable tokens compatible with CancellationTokenSource.
7. Attachment model:
   - Implement widget.attachmentModel.addContext/addFile/addFolder APIs and ensure attachments can be serialized into requests.
8. Accessibility hooks:
   - Provide an accessibility signal service (playSignal) or a no-op shim to preserve A11y behavior when clearing.

Cross-links
- Codeblock embedding / editor pools and lifecycle: [`src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1`](src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1)
- Markdown decorations / response post-processing: [`src/vs/workbench/contrib/chat/browser/chatMarkdownDecorationsRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownDecorationsRenderer.ts:1)
- Widget & session services/interfaces: [`src/vs/workbench/contrib/chat/browser/chat.ts:1`](src/vs/workbench/contrib/chat/browser/chat.ts:1)

Short actionable TODOs
- Add unit tests for reindentation and indentation computation (`computeIndentation`).
- Add integration tests for InsertCodeBlockOperation and ApplyCodeBlockOperation covering text & notebook editors.
- Document required shims in PORTING_CHECKLIST for model resolution, quick-input, bulk edits and code-mapper streaming.

Document prepared from:
- [`src/vs/workbench/contrib/chat/browser/actions/chatClearActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatClearActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatCopyActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatCopyActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatContext.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatContext.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:1`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:1)
