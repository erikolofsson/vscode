# Chat — Tool Invocation: Extensions, I/O Markdown, Terminal, Confirmation

Summary of batch read (files)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatExtensionsInstallToolSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatExtensionsInstallToolSubPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatInputOutputMarkdownProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatInputOutputMarkdownProgressPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalMarkdownProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalMarkdownProgressPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalToolSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalToolSubPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolConfirmationSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolConfirmationSubPart.ts:1)

Responsibilities
- Extensions install confirmation UI and enablement: [`chatExtensionsInstallToolSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatExtensionsInstallToolSubPart.ts:1)
- Input/Output markdown-to-collapsible I/O parts, decoding, permalink creation: [`chatInputOutputMarkdownProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatInputOutputMarkdownProgressPart.ts:1)
- Terminal command rendering as markdown + codeblock and progress wrapper: [`chatTerminalMarkdownProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalMarkdownProgressPart.ts:1)
- Interactive terminal confirmation (editable codeblock) with validation & markers: [`chatTerminalToolSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalToolSubPart.ts:1)
- Generic tool confirmation UI with allow/deny, workspace/session/global allow options and policy storage: [`chatToolConfirmationSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolConfirmationSubPart.ts:1)

Injected services & dependencies
- Extension management listen/install and keybinding/service integration: [`chatExtensionsInstallToolSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatExtensionsInstallToolSubPart.ts:1)
- ModelService/LanguageService for creating temporary models and JSON validation (json.validate command): [`chatToolConfirmationSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatToolConfirmationSubPart.ts:1)
- EditorPool and CodeBlockModelCollection for pooled editors and codeblock tracking: [`chatTerminalToolSubPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatTerminalToolSubPart.ts:1)
- File/permalink helpers (ChatResponseResource) and base64 decoding for binary outputs: [`chatInputOutputMarkdownProgressPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/toolInvocationParts/chatInputOutputMarkdownProgressPart.ts:1)

UI flows & interactions
- Extensions install: shows extension list, listens to extensionInstall events and enables Continue when matching extension installed; confirm completes toolInvocation.confirmed (`chatExtensionsInstallToolSubPart.ts:43`).
- I/O Markdown: builds a collapsible input/output widget, converts text outputs to code blocks or data parts, creates permalink URIs, and wires attachments + resource toolbar (Save As) (`chatInputOutputMarkdownProgressPart.ts:95` and `chatToolInputOutputContentPart.ts:216`).
- Terminal flows: render command as codeblock(s); if confirmation required, show editable codeblock with JSON validation, allow See more to expand; confirmation buttons map to allow/disallow outcomes (`chatTerminalToolSubPart.ts:76` and `chatToolConfirmationSubPart.ts:72`).
- Confirmation decisions: multi-option allow behaviors (session, workspace, global) call ILanguageModelToolsService.setToolAutoConfirmation as appropriate and complete confirmation promise (`chatToolConfirmationSubPart.ts:291`).

Patterns & lifecycle
- Sub-parts subclass BaseChatToolInvocationSubPart and signal onNeedsRerender/onDidChangeHeight; parent part re-renders when necessary (`chatToolInvocationPart.ts:72`).
- Use of WeakMap to preserve expanded state or cached output state across re-renders (`chatInputOutputMarkdownProgressPart.ts:26` had expanded map earlier; tool output used WeakMap caching in other parts).
- Validation uses a debounced RunOnceScheduler to call `json.validate` and update marker service; ensure dispose removes markers (`chatToolConfirmationSubPart.ts:168`).

Porting considerations & risks
- json.validate command and marker service: port must support schema validation hook or replace with an equivalent validation subsystem, and support marker lifecycle (`chatToolConfirmationSubPart.ts:170`).
- Temporary model URIs and ChatResponseResource permalink scheme: preserve deterministic, testable URI generation (stub generateUuid in tests) (`chatInputOutputMarkdownProgressPart.ts:126` & `chatTerminalToolSubPart.ts:152`).
- ExtensionManagement events: install listener used to enable Continue — target platform must expose install events or provide adapter (`chatExtensionsInstallToolSubPart.ts:93`).
- Binary output handling: decodeBase64 and write/copy semantics must be non-blocking and stream-friendly to avoid OOM for large outputs (`chatInputOutputMarkdownProgressPart.ts:116`).
- Policy storage: allow/session/workspace/global settings (setToolAutoConfirmation) need persisted policy; map to configuration service or equivalent storage (`chatToolConfirmationSubPart.ts:294`).

Suggested tests
- Extensions install flow: mock IExtensionManagementService.onInstallExtension and assert continue button enabled and confirmed resolved.
- Terminal confirmation validation: simulate json.validate returns markers and assert markerService updated and cleared on dispose.
- I/O permalink generation and SaveResourcesAction: test decodeBase64 fallback and fileService.copy/write flows with progress reporting.

Next automated actions
1. Write this synthesized note into product_description/features/chat/ (this file)
2. Update TODO to mark this batch completed
3. Continue with remaining chatContentParts not yet synthesized (I will proceed to read the remaining files next)

End of file.
