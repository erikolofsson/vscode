Transfer, Code-block Operations, Tool Picker & Tool Actions

Summary:
This document synthesizes responsibilities, call-sites, lifecycles, porting risks and test proposals for the following source files:
- [`src/vs/workbench/contrib/chat/browser/actions/chatTransfer.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatTransfer.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:1`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/manageModelsActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/manageModelsActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatToolActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatToolActions.ts:1)

1) High-level responsibilities
- Transfer: ChatTransferContribution invokes workspace-trust checks on transfer startup to ensure transferred workspaces meet trust requirements ([`chatTransfer.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatTransfer.ts:1)).
- InsertCodeBlockOperation: inserts code blocks into the active code editor or notebook, handling reindentation, selection and focus management ([`codeBlockOperations.ts:40`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:40)).
- ApplyCodeBlockOperation: invokes the code-mapper service, streams text/notebook edits (AsyncIterable), shows cancellable progress, and offers inline-review before applying edits (`reviewEdits`/`reviewNotebookEdits`) ([`codeBlockOperations.ts:114`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:114)).
- ManageModelsAction: quick-pick UI for selecting vendors and language models, with support for vendor-level management commands and persisting picker preferences ([`manageModelsActions.ts:29`](src/vs/workbench/contrib/chat/browser/actions/manageModelsActions.ts:29)).
- Tools UI (showToolsPicker): dual picker implementations (legacy QuickPick and new QuickTree) to select ToolSets and individual tools, including special handling for MCP servers and toolset buttons ([`chatToolPicker.ts:33`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:33)).
- ConfigureToolsAction / ConfigureToolsActionRendering: user entry for configuring tools, telemetry of enabled/total tools, and a warning indicator when tool counts exceed the configured threshold ([`chatToolActions.ts:79`](src/vs/workbench/contrib/chat/browser/actions/chatToolActions.ts:79)).

2) Call-sites & integrations
- CodeMapper: ApplyCodeBlockOperation uses ICodeMapperService.mapCode and expects the response callbacks textEdit/notebookEdit to emit edits that are consumed as AsyncIterable sequences ([`codeBlockOperations.ts:313`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:313)).
- Inline preview: apply flows call reviewEdits/reviewNotebookEdits to present edits for user review before commit ([`codeBlockOperations.ts:27`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:27)).
- Editor and notebook APIs: logic depends on IEditorService, code editor helpers, notebook insertCell and NOTEBOOK_EDITOR_ID to detect & target editors ([`codeBlockOperations.ts:13,28-31`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:13)).
- Progress & cancellation: uses IProgressService.withProgress with cancellable notifications to surface long-running mapping operations and cancel them via CancellationTokenSource ([`codeBlockOperations.ts:248`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:248)).
- Tools ecosystem: picker integrates ILanguageModelToolsService, IMcpService/IMcpRegistry, extension workbench service and commands to offer install/configure flows and MCP-specific actions ([`chatToolPicker.ts:214,217`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:214)).

3) Lifecycle & state details
- evaluateURIToUse: when a code-block references a non-existent URI, the user is offered choices: create the file, open a new untitled file, or apply to active editor. Creation uses IFileService.writeFile and falls back to untitled URIs on failure ([`codeBlockOperations.ts:187`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:187)).
- Streaming lifetime: code-mapper may produce zero or many edits; the helper waitForFirstElement transforms the incoming AsyncIterable to start yielding only after the first element is available, avoiding races in progress UI ([`codeBlockOperations.ts:356`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:356)).
- Cancellation: CancellationTokenSource is wired to the mapping & progress; errors are filtered with isCancellationError to avoid reporting user-aborted failures ([`codeBlockOperations.ts:246,258`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:246)).

4) Key algorithms & utilities
- reindent: adapts pasted code block indentation to target file indentation using computeIndentation and model.getFormattingOptions; used for InsertCodeBlockOperation to keep pasted code aligned to surrounding context ([`codeBlockOperations.ts:455`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:455)).
- computeIndentation: pure function returning { level, length } given a line string and tabSize — ideal for unit tests and porting verification ([`codeBlockOperations.ts:493`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:493)).

5) UI behaviors & special cases
- Picker feature flag: configurationService.getValue('chat.tools.useTreePicker') toggles between tree and legacy pickers; tree picker gives hierarchical checkboxes and actionable buttons while legacy provides an indented flat list ([`chatToolPicker.ts:576`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:576)).
- MCP server handling: MCP servers are presented as buckets; MCP ToolSets may be stored on the bucket and individual MCP tools appear as direct children. Buttons for configuring MCP collections or showing server output are added to bucket nodes ([`chatToolPicker.ts:281`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:281)).
- Tool limit validation: ChatContextKeys.chatToolGroupingThreshold is read to warn when enabled tool counts exceed a threshold; ConfigureToolsActionRendering shows a warning element in the menu item UI ([`chatToolPicker.ts:634`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:634), [`chatToolActions.ts:206`](src/vs/workbench/contrib/chat/browser/actions/chatToolActions.ts:206)).

6) Porting risks & mitigations
- AsyncIterable streaming: many ports may lack native AsyncIterable-based streaming support for provider callbacks. Mitigation: provide an adapter that buffers the provider's emissions and exposes an AsyncIterable, or change review/apply logic to accept full batches.
- reviewEdits/reviewNotebookEdits dependency: inline review is editor-host specific. If unavailable, implement a lightweight diff/preview modal or fallback to showing textual patch and require explicit user confirmation.
- Notebook APIs: insertCell and notebook edit operations require notebook subsystem support; if absent, either open a new untitled file or apply edits into an existing file view.
- Tree picker parity: if platform's quick-input lacks hierarchical tree widget with checkboxes/buttons, emulate hierarchy in two-level pickers or implement a simple overlay UI.
- MCP registry/service: if MCP concepts do not exist in the target platform, expose MCP tools as extension-based toolsets or collapse MCP buckets into extension buckets; keep configuration actions (open extension or collection) as affordances where possible.
- Error surfacing: file creation/write or code-mapper errors should be presented through IDialogService rather than rethrown to avoid crashes.

7) Tests to add
- Unit: computeIndentation variations (tabs, spaces, mixed, empty lines) and reindent with different tabSize/insertSpaces.
- Unit: evaluateURIToUse flows (resource exists, createFile success, createFile failure, newUntitledFile).
- Integration: ApplyCodeBlockOperation with mocked ICodeMapperService streaming TextEdit sequences — assert progress, inline preview invocation and final application of edits.
- Integration: Tools picker acceptance path for both QuickTree and legacy QuickPick — ensure the resulting Map<ToolSet|IToolData,boolean> matches UI selection and that MCP toolset semantics (toolset enabled only if all tools enabled) are preserved.

8) Implementation notes & recommended changes
- Replace throw/rethrow in import/apply error paths with user-friendly dialogs (IDialogService) including actionable hints (open file, inspect logs).
- Ensure cancellation is fast-pathed into code-mapper providers; failing to cancel can leave progress UI stuck or confuse users.
- Record telemetry for code-mapper durations, edits proposed and cancellations to improve operator diagnostics.
- When creating files, normalize URIs and surfaces to the host file system semantics; provide a clear fallback if write permissions are blocked.

9) Cross-links and related docs
- Actions & tool picker: [`product_description/features/chat/actions_and_tool_picker.md:1`](product_description/features/chat/actions_and_tool_picker.md:1)
- Clear/Copy/Context/Codeblock Ops: [`product_description/features/chat/clear_copy_context_codeblock_ops.md:1`](product_description/features/chat/clear_copy_context_codeblock_ops.md:1)
- Title & misc actions: [`product_description/features/chat/title_and_misc_actions.md:1`](product_description/features/chat/title_and_misc_actions.md:1)

Source references
- [`src/vs/workbench/contrib/chat/browser/actions/chatTransfer.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatTransfer.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:1`](src/vs/workbench/contrib/chat/browser/actions/codeBlockOperations.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/manageModelsActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/manageModelsActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatToolActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatToolActions.ts:1)
