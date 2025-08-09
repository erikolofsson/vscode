# References & Context Actions (Chat)

Purpose: Synthesize behavior and porting notes for chat references UI, extensions content, file-tree content, multi-file diff summary, and chat context/attach actions.

Files reviewed:
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatExtensionsContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatExtensionsContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTreeContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTreeContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:1)

Responsibilities (per file)
- chatReferencesContentPart
  - Renders a collapsible list of references used by a chat response (files, URLs, variables).
  - Uses a pooled WorkbenchList via `CollapsibleListPool` and `ResourcePool` to reuse lists (`get()` returns an IDisposableReference).
  - Special-cases GitHub URLs and settings URIs for friendlier labels; exposes context menu actions (`MenuId.ChatAttachmentsContext`).
  - Provides accessible labels via ResourceLabels and supports drag/drop via `fillEditorsDragData`.
  - Source: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:1)

- chatExtensionsContentPart
  - Lightweight content part that lists contributed extensions (uses `ExtensionsList` and `PagedModel`).
  - Fires onDidChangeHeight when data loaded; created via DI-instantiated `ExtensionsList`.
  - Source: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatExtensionsContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatExtensionsContentPart.ts:1)

- chatTreeContentPart
  - Renders a compact file-tree for response-progress file data using `WorkbenchCompressibleAsyncDataTree`.
  - Uses a `TreePool` (ResourcePool) for pooling tree instances; supports open/collapse and emits height changes.
  - Uses ResourceLabels and explorer decorations; opens files with IOpenerService.
  - Source: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTreeContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTreeContentPart.ts:1)

- chatMultiDiffContentPart
  - Renders a summary UI for multiple-file diffs produced by an editing session.
  - Presents a compact list (WorkbenchList) with a "view all" button that opens a `MultiDiffEditorInput`.
  - Provides per-item open behavior (open file or diff) via IEditorService and IEditorGroupsService.
  - Source: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1)

- chatContextActions
  - Registers a set of actions for attaching resources to chat: files, folders, selection, search results, and a generic "Add Context..." pick.
  - Key responsibilities:
    - Resolve editor/search context into URIs and ranges.
    - Use `IChatWidgetService` to find the focused widget (or open the chat view).
    - For quick/context pick: query `IChatContextPickService`, build quick-pick items, and handle selected attachments.
    - For file-like picks validate model availability via `ITextModelService.createModelReference` and mark omitted state if unavailable.
    - For image resources, read bytes then `resizeImage` and attach as image payload.
  - Source: [`src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:1)

Common patterns and implementations
- Pooling: multiple content parts use `ResourcePool<T>` wrappers that return IDisposableReference: { object, isStale(), dispose() }.
  - Important to implement identical acquire/release semantics in the target platform to avoid leaking DOM or editors.
  - References: `CollapsibleListPool.get()` and `TreePool.get()`.
    - See [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:261`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatReferencesContentPart.ts:261)
    - See [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTreeContentPart.ts:139`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTreeContentPart.ts:139)

- Accessible resource labels and theming: ResourceLabels are used extensively to create file/name/description views with icons, decorations and ARIA labels.
  - Porting should provide an equivalent label component and theming hooks.

- Lists/Trees: WorkbenchList and WorkbenchCompressibleAsyncDataTree are used with virtual delegates, renderers, and identity providers.
  - The target platform needs virtualized list/tree with dynamic heights, compression (grouping of contiguous nodes) and identityProvider support.
  - See list/tree renderer and delegate implementations inside these files.

UI flows & interactions
- Opening items: list/tree onDidOpen handlers call IOpenerService.open or IEditorService.openEditor; selection preserves focus.
- Context menus/toolbar: Collapsible lists may include MenuWorkbenchToolBar bound to `MenuId.ChatAttachmentsContext`. Actions like "Add File to Chat" are registered via `registerAction2`.
  - See resource-menu actions at end of `chatReferencesContentPart`.

Attach / Context pick flow (detailed)
- Trigger: user invokes AttachContext or clicks attach toolbar.
- The `AttachContextAction` builds quick-pick items from `IChatContextPickService.items`, filters with item.isEnabled(widget).
- QuickPick integration:
  - Uses AnythingQuickAccessProvider / QuickInputService with providerOptions.handleAccept for handling picks.
  - Picker supports nested pickers (pickerPick) and value picks.
- When the user accepts:
  - For resource picks: images are read (IFileService.readFile) and resized via `resizeImage` before attaching as { kind: 'image', value: binary }.
  - For file picks: attempts to create a model reference to detect omission; sets omittedState accordingly.
  - For symbol/goto picks: attaches { uri, range } as generic context.
- After adding attachments, the widget input is focused unless the pick was background-accepted.
- Reference: behavior and edge cases in [`src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:1`](src/vs/workbench/contrib/chat/browser/actions/chatContextActions.ts:1)

Porting considerations & risks
- Platform primitives required:
  - DI container and service registration (IInstantiationService).
  - Virtualized list/tree components with renderer/delegate model and support for context menus and accessibility.
  - Resource label system (ResourceLabels) that can render file icons, descriptions and decorations.
  - Quick input / quick-pick system capable of nested pickers, background accept, and observable picks.
  - Editor / opener services to open files/diffs and create model references (`IEditorService`, `ITextModelService`).
  - Menu/Action system with context key expressions and menu ids.
  - File service and workspace storage to read files for image attachments.

- Critical behaviors to replicate exactly:
  - Pooling semantics (isStale / dispose) to avoid reused list/tree instances being mutated when still mounted.
  - GitHub URI label parsing and range extraction for better UX.
  - The omitted-state detection for files that cannot be loaded (createModelReference failure path).
  - Image resize before attaching to keep attachments within size/format constraints.

- Security/privacy:
  - Attachment handling reads local files and image bytes; port must ensure user consent and storage lifetime and implement cleanup policies similar to original (e.g., temp workspace storage TTL).

Tests to add / validation harness
- Unit tests:
  - CollapsibleListRenderer rendering variations (file, URL, variable, warning).
  - Tree compression and identityProvider behavior.
  - MultiDiff list open behavior (open diff vs file).
- Integration tests:
  - AttachContext quick-pick flows (valuePick, pickerPick, go back, configure).
  - Image attach path: readFile -> resizeImage -> addContext.
  - Omitted detection: simulate createModelReference throwing and verify omittedState.

Short prioritized porting checklist (top items)
1. Implement or adapt a ResourceLabels component and virtualized WorkbenchList/Tree (high).
2. Implement pooling semantics for lists/trees and code/editor pools (high).
3. Provide quick-pick/quick-input provider options and nested picker support (medium).
4. Wire editor/opener services and model reference APIs (high).
5. Implement image read/resize utilities and secure storage with cleanup (medium).

Cross-links
- Related feature docs: [`product_description/features/chat/attachments_and_markdown.md:1`](product_description/features/chat/attachments_and_markdown.md:1), [`product_description/features/chat/attachments_widget_and_editor.md:1`](product_description/features/chat/attachments_widget_and_editor.md:1), [`product_description/features/chat/textedit_diff.md:1`](product_description/features/chat/textedit_diff.md:1)

End of synthesized notes.
