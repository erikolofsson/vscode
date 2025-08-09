Onboarding, Import/Export, Language Model, Move & Quick Input Actions

Summary:
This document synthesizes responsibilities, call-sites, lifecycles, UI flows, porting risks and test ideas for the chat actions implemented in the following source files:
- [`src/vs/workbench/contrib/chat/browser/actions/chatGettingStarted.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatGettingStarted.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatImportExport.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatImportExport.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatLanguageModelActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatLanguageModelActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatMoveActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatMoveActions.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatQuickInputActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatQuickInputActions.ts:1)

1) Responsibilities (high-level)
- Onboarding / welcome: [`ChatGettingStartedContribution`](src/vs/workbench/contrib/chat/browser/actions/chatGettingStarted.ts:18) listens for the default product chat agent's extension installation/activation and opens the Copilot/Welcome view once on first activation.
- Export / Import: the `ExportChatAction` and `ImportChatAction` pair in [`chatImportExport.ts`](src/vs/workbench/contrib/chat/browser/actions/chatImportExport.ts:25) implement file save/open dialogs and use the file service to serialize/deserialize session state via model.toExport() / IChatEditorOptions.
- Language-model access management: [`ManageLanguageModelAuthenticationAction`](src/vs/workbench/contrib/chat/browser/actions/chatLanguageModelActions.ts:23) surfaces a grouped QuickPick for managing allowed extensions per language-model provider and writes back via IAuthenticationAccessService.
- Move/placement actions: actions registered in [`chatMoveActions.ts`](src/vs/workbench/contrib/chat/browser/actions/chatMoveActions.ts:31) move chat between Panel, Editor, Sidebar and New Window, preserving sessionId and viewState when available.
- Quick chat UX & keybindings: [`QuickChatGlobalAction`](src/vs/workbench/contrib/chat/browser/actions/chatQuickInputActions.ts:68) and related actions implement global toggle, open/close and open-in-view shortcuts and wire the IQuickChatService.

2) Call-sites and integrations
- The onboarding contribution hooks into extension installation and activation events via IExtensionManagementService.onDidInstallExtensions and IExtensionService.onDidChangeExtensionsStatus (`src/vs/workbench/contrib/chat/browser/actions/chatGettingStarted.ts:1`).
- Export flow uses IChatWidgetService.lastFocusedWidget to get the active widget, IChatService.getSession(sessionId) to fetch model, and FileDialogService + FileService to write JSON (`src/vs/workbench/contrib/chat/browser/actions/chatImportExport.ts:1`).
- Import flow reads a file and opens a new ChatEditorInput using `ChatEditorInput.getNewEditorUri()` with options { target: { data } } so the editor is instantiated as a pinned, data-backed session.
- Language model management enumerates ILanguageModelsService language model registrations, then uses authenticationAccessService.readAllowedExtensions/updateAllowedExtensions to persist changes.
- Move actions use IEditorService.openEditor with ChatEditorInput.getNewEditorUri() to create editor-hosted chat, and viewsService.openView(ChatViewId) to move sessions into the panel; helper functions `executeMoveToAction` and `moveToSidebar` centralize logic.
- Quick chat toggling calls IQuickChatService.toggle/openInChatView/close with selection information (Selection instances created from provided query strings).

3) Lifecycle & state details
- Onboarding: `ChatGettingStartedContribution` stores a machine-scoped key (`workbench.chat.hideWelcomeView`) after opening the welcome view once. It tracks a transient recentlyInstalled flag to only open upon post-install activation.
- Import/Export: exported JSON is produced by model.toExport() — the export format must be validated by `isExportableSessionData` during import to avoid corrupt session injection. Imported sessions are provided as `options.target.data` to the editor.
- Moving sessions: when moving from panel → editor, the widget `clear()` + `waitForReady()` sequence is used to detach UI state; viewState and sessionId are passed into new editor input options to preserve scroll/selection.
- Language model auth flows: QuickPick returns picked items and the action diffs the set per ownerId and calls `authenticationAccessService.updateAllowedExtensions(...)`.

4) Public APIs / dependencies to replicate when porting
- registerAction2 / Action2 based commands with Menu registrations and context preconditions (`ChatContextKeys.enabled`) — port must replicate menu/command registration & conditional visibility.
- IQuickInputService QuickPick groups and separator buttons (onDidTriggerSeparatorButton / onDidTriggerItemButton) used to open extensions — need QuickPick API parity or fallback UI.
- File dialog & file services: showSaveDialog/showOpenDialog + FileService.readFile/writeFile to persist session JSON. The `joinPath(await defaultFilePath(), defaultFileName)` pattern is used to choose defaults.
- ILanguageModelsService / IAuthenticationAccessService contract: language model registrations expose .auth info, and auth service supports readAllowedExtensions / updateAllowedExtensions APIs. Product-level trusted-extension mappings are applied (productService.trustedExtensionAuthAccess).
- Editor integration: ChatEditorInput.getNewEditorUri(), IEditorService.openEditor, and IViewsService.openView with ChatViewId are essential for move and import flows.

5) UI flows and points of friction
- On first install: onboarding auto-opens the Copilot view — port should decide whether to auto-open or provide an explicit welcome entry depending on platform expectations and OS-level permission models.
- Import validation: parsing and isExportableSessionData guard is critical; on malformed files the current code throws (rethrows). Ports should surface a user-friendly error dialog instead of an uncaught exception.
- QuickPick complexity: the language model management QuickPick contains separators, disabled/trusted items and action buttons. If the target platform quick-picker lacks separator-button callbacks, replace with a two-stage dialog or an HTML-based picker.
- Moving editors: the code assumes editors and views can be swapped programmatically and that viewState can be preserved — this requires editor host APIs (open/close/restore) with auxiliary bounds support.

6) Data model / persistence
- Export format: model.toExport() is the single source-of-truth for exported sessions. The importer expects the shape validated by `isExportableSessionData` (`src/vs/workbench/contrib/chat/browser/actions/chatImportExport.ts:1`).
- Storage key: onboarding uses StorageService with key `workbench.chat.hideWelcomeView` (application scope, machine target).
- Language-model allowed list: persisted via authenticationAccessService; productService may inject trusted defaults that the UI marks as disabled.

7) Porting risks and mitigation
- Risk: No equivalent for IAuthenticationAccessService / ILanguageModelsService. Mitigation: provide a simplified "Manage Models" flow that lists model owners and opens extension pages; fall back to documentation links if fine-grained auth isn't required.
- Risk: Missing QuickPick features (separator buttons, item buttons). Mitigation: implement a small HTML picker overlay or split the workflow into "Open extension" buttons that open extension pages separately.
- Risk: Editor/view movement semantics differ (no ChatEditorInput-like concept). Mitigation: emulate session persistence by serializing session state and rehydrating in new host; preserve viewState where possible (scroll offsets, selection).
- Risk: Import may allow malicious JSON -> arbitrary session content. Mitigation: keep `isExportableSessionData` checks and present user confirmation dialogs; sanitize/whitelist fields on import.

8) Tests to add (unit + integration)
- Unit: verify `isExportableSessionData` rejects unexpected shapes; test toExport() output shape and round-trip import path via ChatEditorInput opening.
- Unit: onboarding: simulate extension install + activation and ensure `showCopilotView` is called once and storage key is written.
- Integration: move-to-editor/window/sidebar preserves sessionId and viewState. Use mocked IEditorService + IViewsService to ensure correct calls to openEditor/openView.
- Integration: language-model QuickPick selection persists via updateAllowedExtensions with correct filtering of trusted entries.

9) Implementation notes & recommended port decisions
- Prefer safe import behavior: replace "throw err" in import with a user-facing dialog (IDialogService.prompt) and a clear error message (see `src/vs/workbench/contrib/chat/browser/actions/chatLanguageModelActions.ts:1` use of dialogService.prompt).
- For QuickPick gaps, implement a small HTML overlay (in-host) that can show grouped lists with action-buttons — this is especially helpful for managing language-model permissions where "Open Extension" buttons exist.
- Keep onboarding opt-out persistent and machine-scoped; on platforms that restrict auto-opening windows, instead surface a prominent notification with an "Open chat" action.

10) Cross-links to authored docs / related features
- Actions & Tool Picker: [`product_description/features/chat/actions_and_tool_picker.md:1`](product_description/features/chat/actions_and_tool_picker.md:1)
- Clear/Copy/Context/Codeblock Ops: [`product_description/features/chat/clear_copy_context_codeblock_ops.md:1`](product_description/features/chat/clear_copy_context_codeblock_ops.md:1)
- Title and misc actions: [`product_description/features/chat/title_and_misc_actions.md:1`](product_description/features/chat/title_and_misc_actions.md:1)

11) Suggested follow-ups
- Replace import error throw with dialog and add unit tests.
- Add integration mocks for editor/view movement and run E2E scenario to validate session rehydration.
- Add a short "Porting guidance" section to the master MANIFEST summarizing critical runtime contracts (QuickPick, FileService, Editor open/close).

Source references (for reviewers)
- [`ChatGettingStartedContribution`](src/vs/workbench/contrib/chat/browser/actions/chatGettingStarted.ts:18)
- [`ExportChatAction` / `ImportChatAction`](src/vs/workbench/contrib/chat/browser/actions/chatImportExport.ts:25)
- [`ManageLanguageModelAuthenticationAction`](src/vs/workbench/contrib/chat/browser/actions/chatLanguageModelActions.ts:23)
- [`executeMoveToAction`](src/vs/workbench/contrib/chat/browser/actions/chatMoveActions.ts:113)
- [`QuickChatGlobalAction` / `ASK_QUICK_QUESTION_ACTION_ID`](src/vs/workbench/contrib/chat/browser/actions/chatQuickInputActions.ts:68)
