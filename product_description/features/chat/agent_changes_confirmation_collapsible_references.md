Chat: Agent Commands, Changes Summary, Confirmation Widget, Collapsible Parts & References

Summary
This document captures responsibilities, UI flows, lifecycle patterns, injected services and porting considerations for:
- Agent command buttons embedded in responses
- Checkpoint/changes summaries across responses
- Confirmation widgets and query title parts
- Collapsible references lists, pools, and resource context menus

Key files
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatAgentCommandContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAgentCommandContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatChangesSummaryPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatChangesSummaryPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationWidget.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatConfirmationWidget.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatContentParts.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatContentParts.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:1)

Responsibilities (per-component)
- Agent command part: render inline agent subcommands (prefixed), provide hover with description, and a small "close/rerun" button to trigger onClick. Accessible role button and aria-label set.
- Changes summary: render a collapsible summary of file changes (Checkpoint), compute diffs via editSession.getEntryDiffBetweenStops, render a compact list with insertions/deletions labels and 'view all' multi-diff action.
- Confirmation widget: reusable BaseChatConfirmationWidget providing title rendering, message rendering, notification to host window if configured, and buttons (including dropdowns). ChatQueryTitlePart handles title rendering and height events.
- Collapsible references: reusable ChatCollapsibleContentPart + ChatCollapsibleListContentPart that use CollapsibleListPool to obtain WorkbenchList instances, render items with ResourceLabels, provide dnd, context menu actions and expose accessible labels.
- Cross-cutting: ResourcePool pattern used for pooling lists/trees/editors; parts should call addDisposable() to attach disposables.

Injected services & runtime deps
- HoverService for inline hover tooltips.
- IChatService, IEditorService, IEditorGroupsService, IInstantiationService for change diffs and editors.
- Menu actions & toolbar services: MenuWorkbenchToolBar, MenuId, registerAction2 for context/menu actions (AddToChatAction, CopyLink).
- Clipboard, ContextMenu, Label, Theme, Opener services used by references and attachments.
- ResourcePools and CollapsibleListPool/TreePool for pooled widgets.

UI flows & interactions
- Agent commands: show command text with hover (description) and icon button; clicking button triggers onClick to rerun behavior.
- Changes summary: compute diffs lazily via derived observable over edit sessions; view-all opens MultiDiffEditorInput; list entries open editor/diff on open.
- Confirmation widget: render messages via MarkdownRenderer, fire onDidChangeHeight when async rendering changes layout, optionally notify OS-level notification with click-to-focus behavior.
- References: list items support context menus derived from MenuId.ChatAttachmentsContext and AddToChat action; DnD support via fillEditorsDragData to allow dragging to editor tabs.

Lifecycle & contracts
- ChatQueryTitlePart._renderedTitle is a MutableDisposable to ensure previous render results are disposed when updating title.
- BaseChatConfirmationWidget.setShowButtons toggles 'hideButtons' class; renderMessage triggers host notification if configured.
- CollapsibleListPool.get returns IDisposableReference wrapper with isStale/dispose that sets stale=true and returns pooled list.
- computeFileChangesDiffs uses derived observables reading editSession.promiseResult to compute per-file diffs between stops.

Porting considerations & risks
- Menu/Action system: heavy reliance on VS Code's MenuId/MenuWorkbenchToolBar/registerAction2. Host must support a menu/action system or provide adapters.
- Editor/diff APIs: MultiDiffEditorInput and editSession.getEntryDiffBetweenStops are specific; port must supply multi-diff UX or alternative.
- Notification & focus behavior: notifyConfirmationNeeded uses hostService.focus and dom.triggerNotification; platform differences may require alternative notification APIs.
- Resource pooling and stale semantics: preserve isStale flag and reset/reuse semantics to avoid using changed list/tree instances after reuse.
- DnD and label rendering: ResourceLabels and file-icon theming require host implementation for drag data and file decorations.

Tests & verification
- Unit: AgentCommandContentPart hover registration and click triggers onClick.
- Integration: Changes summary lists proper diff counts, 'view all' opens multi-diff with correct resources, and list items open editors appropriately.
- Integration: Confirmation widget notifications appear when configured and clicking the notification focuses window and opens chat view.

Verbatim patterns to preserve
- CollapsibleListPool.get() IDisposableReference wrapper:
  const object = this._pool.get();
  let stale = false;
  return { object, isStale: () => stale, dispose: () => { stale = true; this._pool.release(object); } };
- computeFileChangesDiffs derived pattern:
  derived((r) => { for (const change of changes) { const editSession = this.chatService.getSession(sessionId).editingSessionObs.promiseResult.read(r)?.data; const diff = editSession.getEntryDiffBetweenStops(...).read(r); ... } return fileChangesDiffs; });

Accessibility notes
- Agent command DOM node uses role='button' and aria-label; ensure keyboard operation and hover text are preserved.
- Collapsible lists and confirmation widgets expose aria labels and keyboard handlers (Enter/Space).

Next steps
- Add this document to MANIFEST and continue reading any remaining chatContentParts under toolInvocationParts/ and media/ to complete coverage.
