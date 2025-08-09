# Chat actions, Tool Picker and Codeblock Actions

Overview

This document synthesizes responsibilities, call-sites, UI flows and porting notes for chat actions and the tools picker implementation.

Primary source files

- [`src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:283`](src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:283) — high-level action registrations and title-bar menus (registerChatActions).
- [`src/vs/workbench/contrib/chat/browser/actions/chatExecuteActions.ts:905`](src/vs/workbench/contrib/chat/browser/actions/chatExecuteActions.ts:905) — submit/cancel/execute actions (registerChatExecuteActions).
- [`src/vs/workbench/contrib/chat/browser/actions/chatToolActions.ts:234`](src/vs/workbench/contrib/chat/browser/actions/chatToolActions.ts:234) — tool configuration and telemetry (registerChatToolActions).
- [`src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:127`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:127) — codeblock actions (registerChatCodeBlockActions).
- [`src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:568`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:568) — tools picker UI (showToolsPicker).

Responsibilities

- Wire commands, menus and keybindings to widget behaviors and model operations (open view, focus input, submit, cancel). See [`registerChatActions()`](src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:283) and [`registerChatExecuteActions()`](src/vs/workbench/contrib/chat/browser/actions/chatExecuteActions.ts:905).
- Provide tool-selection and configuration UI, including both legacy QuickPick and new QuickTree implementations. Entry point: [`showToolsPicker()`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:568).
- Handle code-block specific actions (copy, insert, runInTerminal, apply edits) and map editor context -> chat codeblock context. See [`registerChatCodeBlockActions()`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:127).
- Telemetry for tool selection and copy/insert/run actions (e.g., 'chat/selectedTools', copy events emitted via IChatService.notifyUserAction in [`chatCodeblockActions.ts:144`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:144)).

Key objects and APIs used (injected services)

- IChatService, IChatWidgetService — to get widget, model and session context ([`chatActions.ts:140`](src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:140)).
- ILanguageModelToolsService — enumerating tools and toolSets, retrieving tool metadata ([`chatToolPicker.ts:25`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:25)).
- IQuickInputService / IQuickTree — UI primitives for pickers ([`chatToolPicker.ts:207`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:207)).
- IMcpService / IMcpRegistry / IMcpWorkbenchService — MCP server integration and special-casing ([`chatToolPicker.ts:208`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:208)).
- CommandsRegistry / ICommandService — to execute extension commands, open settings and install extensions.
- IInstantiationService — create parser/operations, e.g., ChatRequestParser and ApplyCodeBlockOperation ([`chatExecuteActions.ts:596`](src/vs/workbench/contrib/chat/browser/actions/chatExecuteActions.ts:596), [`chatCodeblockActions.ts:279`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:279)).

UI flows and behaviors

- Open chat / focus input:
  - Actions like `workbench.action.chat.open` and mode-specific open actions call into view open + widget.focusInput via [`OpenChatGlobalAction.run`](src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:137).

- Submit/cancel flow:
  - `ChatSubmitAction` / `CancelAction` wired with menu placements and keybindings; `SubmitAction` logic validates editing session and may undo edits (see [`chatExecuteActions.ts:49`](src/vs/workbench/contrib/chat/browser/actions/chatExecuteActions.ts:49)).

- Tools configuration:
  - `ConfigureToolsAction` opens the picker via [`showToolsPicker()`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:568). Two implementations exist:
    - Tree picker: [`showToolsPickerTree()`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:199) (hierarchical, checkboxes, MCP special handling).
    - Legacy QuickPick: [`showToolsPickerLegacy()`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:594) (flat list with indentation).
  - Feature flag `chat.tools.useTreePicker` controls which implementation ([`chatToolPicker.ts:576-579`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:576)).

- MCP server special-case:
  - MCP servers are represented as buckets and their tools appear as children; MCP ToolSet is stored on the bucket (see [`chatToolPicker.ts:281`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:281)).

- Tool limit validation:
  - Picker computes enabled tool count and uses ChatContextKeys.chatToolGroupingThreshold to warn users (`chatToolPicker.ts:460`).

- Tool configuration buttons:
  - Picker buttons for "Add MCP Server", "Install Extension", "Configure Tool Sets" call CommandsRegistry / extensions service (`chatToolPicker.ts:522`).

Call-sites & registrations

- Menu registrations: title bar, view title, editor context menus are registered in [`chatActions.ts:1271`](src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:1271) and surrounding code.
- Action registrations across files:
  - [`registerChatActions()`](src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:283)
  - [`registerChatExecuteActions()`](src/vs/workbench/contrib/chat/browser/actions/chatExecuteActions.ts:905)
  - [`registerChatToolActions()`](src/vs/workbench/contrib/chat/browser/actions/chatToolActions.ts:234)
  - [`registerChatCodeBlockActions()`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:127)

Porting risks & fragilities

- QuickTree / QuickPick UI primitives:
  - The new tree picker uses IQuickTree. Ports must provide a hierarchical quick picker or implement a compatible fallback. (`chatToolPicker.ts:404`).

- MCP integration:
  - Tool picker relies on MCP services (`IMcpService`, `IMcpRegistry`) for server discovery and actions; missing MCP equivalents require stubbing or changing UX.

- ToolSet semantics:
  - ToolSet vs IToolData mapping, toolset.checked behavior (MCP special-case) and ToolDataSource keys must be preserved to match backend expectations.

- Context keys and menu system:
  - The actions depend on many context keys (ChatContextKeys.*). Ports must support a similar contextkey system or rework menu visibility conditions.

- Commands & extension activation:
  - Picker buttons open extension features or run MCP commands — ports without extension workbench must adapt.

- Telemetry surface:
  - Telemetry events (e.g., 'chat/selectedTools') are emitted — ensure telemetry shims exist or strip sensitive signals.

- Editor-integration for codeblock apply/run:
  - Actions like ApplyCodeBlockOperation and InsertCodeBlockOperation rely on EditorService, TerminalService and code editor models. Ports need matching editor APIs and transient model pinning to reproduce behavior.

Recommended tests

- Unit: map ToolSet/tool -> tree/pick items, MCP bucketing logic, ToolSet enabled computation.
- Unit: validate showToolsPicker respects `chat.tools.useTreePicker` flag and returns the same shape from both implementations.
- Integration: picker -> onUpdate callback invoked when user toggles items and the returned Map matches selection.
- Integration: tool limit threshold triggers validationMessage and severity.
- E2E: ConfigureToolsAction path opens picker and persists selection to selectedToolsModel.
- E2E: Accept tool confirmation action resolves tool invocation confirmables in [`chatToolActions.ts:69`](src/vs/workbench/contrib/chat/browser/actions/chatToolActions.ts:69).

Implementation adapter checklist for porting

1. Provide QuickPick and QuickTree UI primitives (IQuickInputService / IQuickTree) or adapt to platform-native pickers.
2. Implement ILanguageModelToolsService shim exposing ToolSet and IToolData with getTools(), source metadata and canBeReferencedInPrompt.
3. Expose IMcpService/IMcpRegistry or alter tool picker to ignore MCP buckets when MCP is unavailable.
4. Provide CommandsRegistry and ICommandService equivalents for invoking extension actions and opening settings/editors.
5. Provide contextkey system and ChatContextKeys to support menu visibility.
6. Provide telemetry shim or disable telemetry events as required.
7. Ensure editor/terminal services to support codeblock actions (runInTerminal, insert into editor, apply edits).

Cross-links

- See codeblock embedding and apply flow: [`src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1`](src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1)
- See markdown decorations and post-processing: [`src/vs/workbench/contrib/chat/browser/chatMarkdownDecorationsRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownDecorationsRenderer.ts:1)
- See session / widget interfaces: [`src/vs/workbench/contrib/chat/browser/chat.ts:1`](src/vs/workbench/contrib/chat/browser/chat.ts:1)

Short actionable TODOs

- Add unit tests for ToolSet <-> picker mapping.
- Add a "picker fallback" note in PORTING_CHECKLIST about replacing QuickTree with native tree pickers.
- Cross-link feature doc into MANIFEST.md and update PORTING_CHECKLIST.

Document prepared from: [`src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatActions.ts:1), [`src/vs/workbench/contrib/chat/browser/actions/chatExecuteActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatExecuteActions.ts:1), [`src/vs/workbench/contrib/chat/browser/actions/chatToolActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatToolActions.ts:1), [`src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatCodeblockActions.ts:1), [`src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatToolPicker.ts:1)
