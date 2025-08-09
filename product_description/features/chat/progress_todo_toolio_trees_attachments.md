Chat: Progress, Todo List, Tool I/O, Trees & Attachments

Summary
This document summarizes responsibilities, UI flows, lifecycle patterns, injected services and porting considerations
for the following chat content parts.

Key files
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTodoListWidget.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTodoListWidget.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTreeContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTreeContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1)

Responsibilities (per-component)
- Progress content: render progress messages, optionally show spinner, hide when subsequent non-progress content appears, and alert screen-readers for active streaming.
- Todo list widget: manage per-session todo lists, toggle expand/collapse, expose height and update on session change.
- Tool I/O: render collapsible input/output blocks with pooled code editors, attachments list, resource toolbars, save/download flows and context menu wiring.
- Tree content: provide file-tree rendering with pooled WorkbenchCompressibleAsyncDataTree instances, open URIs on selection, and fire height/layout updates.
- Attachments: create appropriate attachment widgets by type (images, files, paste, notebook output, tool items), manage hover/tooltip and context menu handlers.

Injected services & dependencies
- MarkdownRenderer, IInstantiationService, IChatMarkdownAnchorService
- IChatTodoListService
- Editor/model services: IEditorService, IModelService, ITextModelService, EditorPool (ResourcePool)
- File and dialog services: IFileService, IFileDialogService, IWorkspaceContextService, ILabelService
- Menu/Actions/ContextMenu: MenuWorkbenchToolBar, MenuId, IContextMenuService, registerAction2/Action2
- Tree & list services: WorkbenchCompressibleAsyncDataTree, ResourceLabels, ThemeService

UI flows
- Progress: show placeholder or full progress step depending on following content; show spinner when response is streaming and no later content; call alert(progress.content.value) when spinner shown for SR.
- Todo list: updateSessionId(sessionId) → fetch stored todos → render list or hide widget; expando toggles aria-expanded and fires height events.
- Tool I/O: title + input codeblock rendered via pooled editors; outputs may include code blocks (editors) or data parts (attachments); attachments get a toolbar (MenuWorkbenchToolBar) and context menu (ChatToolOutputResourceContext).
- Tree: acquire tree via TreePool.get(), setInput(data) and layout once ready; onDidOpen opens file/diff via IOpenerService; onCollapse triggers height update.
- Attachments: instantiationService creates specific widget classes; widgets receive hoverDelegate and ResourceLabels; contextmenu events forwarded via contextMenuHandler.

Lifecycle patterns & contracts
- Progressive hiding: ChatProgressContentPart.hasSameContent returns false when a following non-progress content appears so rendering collapses; reproduce in host.
- Resource pools: ResourcePool<T> with get() / release(item) and inUse set; EditorPool wraps ResourcePool and returns IDisposableReference with isStale/dispose/reset pattern.
- Tree pooling: TreePool creates WorkbenchCompressibleAsyncDataTree instances and returns IDisposableReference with isStale and release semantics.
- Attachment widget ownership: ChatAttachmentsContentPart registers widgets in a DisposableStore and disposes them when container cleared or part disposed.
- Tool I/O save flow: SaveResourcesAction.run uses IFileDialogService to pick location, fileService.copy or read/write, and progressService.withProgress for batched saves.

Porting considerations & risks
- Screen reader alerts: chatProgress calls alert(progress.content.value) when spinner shown — ensure host SR integration is equivalent.
- Pooling semantics: _register(this._itemFactory()) used inside ResourcePool ensures pool owns disposables — preserve owner/disposal semantics to avoid leaks.
- Editor ephemeral models: code uses ITextModelService.createModelReference and transient editors; host must support ephemeral models or adapt flow.
- Large binary attachments & save: SaveResourcesAction reads/writes files and uses fileService.copy where possible; careful with streaming/memory limits on target platform.
- Menu/Action registration: registerAction2 is used to add SaveResourcesAction to MenuId.ChatToolOutputResourceToolbar and Context — adapt to host menu system.
- Tree compression & identity: WorkbenchCompressibleAsyncDataTree compression delegate & identityProvider used for grouping; maintain identity provider = uri.toString().

Tests and verification
- Unit: ChatProgressContentPart.shouldShowSpinner logic for streaming vs settled responses; ChatTodoListWidget.updateSessionId renders correct visibility.
- Unit: ResourcePool get/release and inUse tracking; EditorPool.get() stale/dispose behavior and reset called on dispose.
- Integration: ChatCollapsibleInputOutputContentPart save flow: simulate multiple parts and verify fileDialog interactions, fileService.copy/read/write and progress reporting.
- Integration/UI: ChatTreeContentPart opens correct editor inputs for diffs vs single files and layouts after setInput.

Verbatim patterns to preserve
- ResourcePool pattern:
const item = this._register(this._itemFactory());
_inUse.add(item);
...
release(item) { this._inUse.delete(item); this.pool.push(item); }
- EditorPool IDisposableReference wrapper:
const ref = this._pool.get();
let stale = false;
return { object: codeBlock, isStale: () => stale, dispose: () => { codeBlock.reset(); stale = true; this._pool.release(codeBlock); } };
- SaveResourcesAction.run savePart and withProgress snippet (preserve order and progress reporting).

Accessibility notes
- Preserve alert() usage and tabIndex/aria-expanded/ariaLabel updates used across parts.
- Ensure keyboard handlers (Enter/Space) on interactive elements (todo expando, collapsed code pill) are preserved.

Porting checklist entries
- Implement host adapters for ResourcePool and IDisposableReference semantics.
- Provide ephemeral text model API equivalent to ITextModelService.createModelReference.
- Map MenuId and registerAction2 usages to host menu/action system for toolbar/context actions.
- Ensure file save/copy APIs allow batch saving with progress reporting.

Next steps
- Add this doc to MANIFEST and continue with remaining files under toolInvocationParts/ and media/ to complete coverage.
