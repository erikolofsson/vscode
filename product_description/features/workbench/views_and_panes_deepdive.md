Views & Panes — Deep Dive

Scope
This document synthesizes the implementation and behavior of Workbench "views" and "panes" (view containers, view panes, tree-based views, menus, toolbars, and drag-and-drop) and highlights adapter-contract implications for porting.

Files examined
- [`src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1`](src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1)
- [`src/vs/workbench/browser/parts/views/viewPane.ts:1`](src/vs/workbench/browser/parts/views/viewPane.ts:1)
- [`src/vs/workbench/browser/parts/views/treeView.ts:1`](src/vs/workbench/browser/parts/views/treeView.ts:1)
- [`src/vs/workbench/browser/parts/views/viewMenuActions.ts:1`](src/vs/workbench/browser/parts/views/viewMenuActions.ts:1)
- [`src/vs/workbench/browser/parts/views/viewsViewlet.ts:1`](src/vs/workbench/browser/parts/views/viewsViewlet.ts:1)

High-level responsibilities
- Host view containers (sidebar/panel/auxiliary) and manage pane layout, sizes and sash interactions.
- Instantiate and lifecycle-manage view panes (render, expand/collapse, focus, save/restore state).
- Provide menus, toolbars and header actions for each view and view container.
- Drive tree-based custom views (data-provider model, rendering, selection, multi-select, checkboxes).
- Support robust drag & drop for both container-level moves (composite → view container) and intra-view DnD (tree items).
- Persist view sizes, collapsed/expanded state, visibility and "merge with container" heuristics.

Lifecycle and creation patterns
- View containers are represented by a ViewContainer + IViewContainerModel (see [`src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1`](src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1)). The container:
  - Creates a PaneView and registers sash/boundary callbacks.
  - Subscribes to view descriptor model events (onDidAdd/Remove/Change) to add/remove panes.
  - Restores sizes on first layout and saves sizes on sash changes.
- Each view is implemented as a ViewPane (see [`src/vs/workbench/browser/parts/views/viewPane.ts:1`](src/vs/workbench/browser/parts/views/viewPane.ts:1)) that:
  - Is constructed with a scoped IContextKeyService and a child IInstantiationService for per-view actions.
  - Renders header (icon, title, optional description), toolbar (WorkbenchToolBar), body and welcome content controller.
  - Exposes events: onDidFocus, onDidBlur, onDidChangeBodyVisibility, onDidChangeTitleArea.

View registration & descriptor model
- Views are declared/registered through the Views registry and surfaced via the IViewDescriptorService. The container obtains view descriptors and a view-container model (visible descriptors, order, sizes).
- The code uses helper methods such as getViewContainerById, getViewDescriptorById, getViewContainerModel to map ids ↔ descriptors.
- Moving views between containers uses viewDescriptorService.moveViewsToContainer(...) and model.move(...) to reorder within a container.

Menus, actions and toolbars
- Per-view menus are managed by `ViewMenuActions` and `ViewContainerMenuActions` (see [`src/vs/workbench/browser/parts/views/viewMenuActions.ts:1`](src/vs/workbench/browser/parts/views/viewMenuActions.ts:1)). These:
  - Wrap the MenuService to provide primary/secondary actions and context-menu actions.
  - Use a scoped contextKeyService to supply `view` and `viewContainer` context keys.
- View header toolbars use `WorkbenchToolBar` and action view item providers; action view items are created via createActionViewItem and menuEntryActionViewItem.
- Common menu ids: MenuId.ViewTitle, MenuId.ViewTitleContext, MenuId.ViewContainerTitle, ViewsSubMenu.

Tree-based views (ITreeView)
- Tree views are implemented by `TreeView`, `CustomTreeView`, and the large `treeView.ts` implementation.
- Core responsibilities:
  - Wrap an ITreeViewDataProvider (from extensions or internal providers) into an async tree widget (`WorkbenchAsyncDataTree`).
  - Render tree node labels, icons, checkboxes and inline per-node actions via `TreeRenderer`.
  - Provide selection/focus events, multi-select, checkbox cascade logic and keyboard/open handling (execute commands).
- The Tree has a batching data-source (TreeDataSource) to coalesce getChildren calls and uses `doGetChildrenOrBatch` to call extension-provided APIs.
- Menus for tree nodes are provided by `TreeMenus` which composes menu actions for multiple selected elements and respects context overlays.

Drag & Drop flows
- Container-level and pane-level DnD is provided via `CompositeDragAndDropObserver` and `ViewPaneDropOverlay`:
  - Dropping a 'composite' (container) into a view pane can move all views between containers.
  - Dropping a 'view' (single view descriptor) triggers viewDescriptorService.moveViewsToContainer and, when in-pane, reorders panes via movePane().
- Tree-specific DnD is handled by `CustomTreeViewDragAndDrop` (see [`src/vs/workbench/browser/parts/views/treeView.ts:1`](src/vs/workbench/browser/parts/views/treeView.ts:1)):
  - Supports extension-provided drag mime types by asking the controller for extra transfer data.
  - Adds resource and file transfer types for OS-level dragging (allows dragging files out).
  - Calls controller.handleDrop(...) with a VSDataTransfer containing filtered types.

Persistence & state
- View sizes are persisted through the viewContainerModel.setSizes(...) and individual view saveState() hooks. On layout the container restores sizes (viewContainerModel.getSize(...)).
- The container uses a storage key `${id}.numberOfVisibleViews` to determine merge-with-container heuristics across restarts.
- Collapsed state is persisted via viewContainerModel.setCollapsed(viewId, collapsed).

Theming and dynamic icons
- Views support both ThemeIcon and URI-based icons. URI icons use dynamic CSS rules created via createCSSRule and CSS mask/background (see [`src/vs/workbench/browser/parts/views/viewPane.ts:1`](src/vs/workbench/browser/parts/views/viewPane.ts:1)).
- Location-based color tokens (sidebar vs panel) are applied via getLocationBasedViewColors(...) and passed into list/tree widget overrideStyles.

Accessibility & focus
- Each ViewPane creates a scoped context key 'view' and 'viewLocation' for menus and commands.
- Tree widget provides rich aria labels and role support; ViewPane computes aria header labels and exposes accessible-view help integration.

Adapter contract callouts (porting)
- Minimal adapters the host must implement or provide equivalents for:
  - ViewDescriptorService adapter: map container ids, descriptors, moveViewsToContainer, getViewContainerModel
  - ViewsService adapter: openViewContainer, getActiveViewPaneContainerWithId, getActiveViewWithId
  - MenuService / MenuRegistry equivalents: menu creation and getMenuActions; support for scoping context keys
  - Drag-and-drop: support for DataTransfer, custom mime types and an async "add drag operation" pattern used by tree DnD
  - StorageService and viewContainerModel persistence (sizes, collapsed)
  - InstantiationService scoping (ability to create per-view child services and a child ServiceCollection)

Porting risks and mitigations
- Host must support dynamic CSS for URI icons or provide an alternative icon resolution strategy; otherwise view icons will break.
- DnD semantics rely on complex DataTransfer handling and extension-provided types; ensure host exposes enough transfer types and an async transfer registration mechanism or emulate it via an in-memory uuid map.
- Lifecycle timing: extensions' view activation is deferred (progress location + lifecycle) in AbstractTreeView — port must respect deferred activation to avoid startup jank.
- Context keys and menu preconditions: host must implement a context-key service that can be scoped per element for menu filtering.

Test proposals (unit / integration)
- View lifecycle:
  - Add/remove view descriptors -> verify pane creation, render, header actions, save/restore sizes.
- Merge-with-container behavior:
  - With single view, validate header merging behavior, persistence via `${id}.numberOfVisibleViews`.
- DnD:
  - Composite → ViewPane drop moves views between containers and reorders panes correctly for different overlay directions (UP/DOWN/LEFT/RIGHT).
  - Tree drag start adds extension transfer types and file resource transfers; drop invokes controller.handleDrop with expected VSDataTransfer contents.
- Tree behavior:
  - Verify checkbox cascading, selection/multi-selection actions, and context menu action composition for multi-selection.
  - Batch getChildren calls from TreeDataSource and robustness when provider resolves after view was hidden or disposed.

Integration points & TODO for adapters
- Provide adapter interface definitions in product_description/src_adapters for:
  - ViewDescriptorAdapter (getViewContainerById, getViewDescriptorById, moveViewsToContainer, getViewContainerModel)
  - ViewsServiceAdapter (openViewContainer, getActiveViewWithId)
  - TreeViewDragAndDropAdapter (handleDrag, handleDrop, dragMimeTypes, dropMimeTypes)

Porting notes & suggested implementation order
1. Implement ViewDescriptor + Views service adapters (mapping identifiers and basic APIs).
2. Implement MenuService adapter (menu registration + scoped context keys).
3. Implement a minimal InstantiationService or factory to construct view instances with scoped contexts.
4. Implement StorageService hooks for view sizes and persisted collapsed state.
5. Implement DnD bridge (DataTransfer + async transfer registration) and test tree DnD flows.

Cross references
- See adapter-contract proposals in [`product_description/src_adapters/workbench_adapters.md:1`](product_description/src_adapters/workbench_adapters.md:1).
- Related Workbench docs: [`product_description/features/workbench/composites_and_activitybar.md:1`](product_description/features/workbench/composites_and_activitybar.md:1), [`product_description/features/workbench/sidebar_panel_and_views.md:1`](product_description/features/workbench/sidebar_panel_and_views.md:1).

Appendix — important source locations
- View pane & container lifecycle: [`src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1`](src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1)
- View base class and header/toolbar behavior: [`src/vs/workbench/browser/parts/views/viewPane.ts:1`](src/vs/workbench/browser/parts/views/viewPane.ts:1)
- Tree view, renderer, DnD controller, batching logic: [`src/vs/workbench/browser/parts/views/treeView.ts:1`](src/vs/workbench/browser/parts/views/treeView.ts:1)
- Menus & action helpers: [`src/vs/workbench/browser/parts/views/viewMenuActions.ts:1`](src/vs/workbench/browser/parts/views/viewMenuActions.ts:1)

End of document.
