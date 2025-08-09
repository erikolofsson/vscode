# Workbench — Views & Viewlets

Summary:
- This document analyzes the Workbench views and viewlet subsystem (view panes, pane containers, tree views, menus, drag & drop)
- Source of truth: [`src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1`](src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1), [`src/vs/workbench/browser/parts/views/viewPane.ts:1`](src/vs/workbench/browser/parts/views/viewPane.ts:1), [`src/vs/workbench/browser/parts/views/viewsViewlet.ts:1`](src/vs/workbench/browser/parts/views/viewsViewlet.ts:1), [`src/vs/workbench/browser/parts/views/treeView.ts:1`](src/vs/workbench/browser/parts/views/treeView.ts:1), [`src/vs/workbench/browser/parts/views/viewMenuActions.ts:1`](src/vs/workbench/browser/parts/views/viewMenuActions.ts:1)

Goals:
- Enumerate responsibilities, lifecycles, public APIs/events
- Identify registration/descriptor & menu/keybinding wiring
- Note UI/UX flows (merge container, drag & drop, welcome content)
- Call out porting risks and adapter needs

Responsibilities
- View container composition and layout (pane management, sash, sizes) — implemented by [`src/vs/workbench/browser/parts/views/viewPaneContainer.ts:291`](src/vs/workbench/browser/parts/views/viewPaneContainer.ts:291)
- Individual view pane header, toolbar, progress, welcome content — implemented by [`src/vs/workbench/browser/parts/views/viewPane.ts:306`](src/vs/workbench/browser/parts/views/viewPane.ts:306)
- Viewlet-level filtering and constant-view descriptors — implemented by [`src/vs/workbench/browser/parts/views/viewsViewlet.ts:22`](src/vs/workbench/browser/parts/views/viewsViewlet.ts:22)
- Tree-based views (custom/extension-provided) including rendering, DnD, context menus, selection/expansion state — implemented by [`src/vs/workbench/browser/parts/views/treeView.ts:81`](src/vs/workbench/browser/parts/views/treeView.ts:81)
- Menu extraction and action grouping for view titles and view container titles — implemented by [`src/vs/workbench/browser/parts/views/viewMenuActions.ts:14`](src/vs/workbench/browser/parts/views/viewMenuActions.ts:14)

Key Concepts & Patterns
- Descriptor / model separation: View descriptors and view container models drive which panes are visible and their metadata via `IViewDescriptorService` and `IViewContainerModel`. See [`viewPaneContainer.ts:371`](src/vs/workbench/browser/parts/views/viewPaneContainer.ts:371).
- Dynamic instantiation: Views are created via InstantiationService using ctor descriptors stored on view descriptors — ViewPaneContainer.createView uses the ctor descriptor (`viewPaneContainer.ts:686`).
- Merge-with-container behavior: When a container has a single view the UI may merge the view header into the container title (mergeViewWithContainerWhenSingleView option) — controlled in [`viewPaneContainer.ts:isViewMergedWithContainer:1096`](src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1096).
- Menu / action wiring: MenuRegistry/MenuId, ViewMenuActions and ViewContainerMenuActions provide primary/secondary menu extraction and context overlays to produce toolbar actions. See [`viewMenuActions.ts:29`](src/vs/workbench/browser/parts/views/viewMenuActions.ts:29) and ViewMenuActions usage in [`viewPane.ts:391`](src/vs/workbench/browser/parts/views/viewPane.ts:391).
- Tree views: heavy use of WorkbenchAsyncDataTree, custom renderer, menus per tree item, drag-and-drop controller abstractions. See [`treeView.ts` references].

Lifecycles
- Registration: Views are registered with the ViewsRegistry (extensions or core code) and appear in the IViewDescriptorService. ViewContainerModel emits onDidAddVisibleViewDescriptors / onDidRemoveVisibleViewDescriptors which drive ViewPaneContainer.add/remove flows (`viewPaneContainer.ts:onDidAddViewDescriptors:516`).
- Creation: When a view descriptor is added, ViewPaneContainer.createView instantiates the concrete ViewPane via instantiationService with IViewletViewOptions and calls pane.render() (see [`viewPaneContainer.ts:771`](src/vs/workbench/browser/parts/views/viewPaneContainer.ts:771)).
- Activation (for extension-provided tree views): The tree view activates its extension on first visible activation using extensionService.activateByEvent(`onView:${id}`) and telemetry is emitted (`treeView.ts:1793-1799`).
- Visibility / layout: ViewPaneContainer.layout delegates to PaneView; view panes save/restore sizes via viewContainerModel.getSize/setSizes (`viewPaneContainer.ts:701`).
- Disposal: Pane disposables are tracked; ViewPaneContainer.dispose disposes pane items and PaneView (`viewPaneContainer.ts:1156`).

Public APIs & Events (surface to host / runtime)
- IViewsService: openViewContainer, getActiveViewPaneContainerWithId, getActiveViewWithId used by actions (ViewPaneContainerAction) (`viewPaneContainer.ts:1172`).
- View descriptors/model events: onDidAddVisibleViewDescriptors, onDidRemoveVisibleViewDescriptors, onDidChangeActiveViewDescriptors — used to update UI and title area (`viewPaneContainer.ts:514-520`, `:539`).
- ViewPane events: onDidFocus, onDidBlur, onDidChangeBodyVisibility, onDidChangeTitleArea — used by container and other services (`viewPane.ts:310-321`).
- Tree view events: onDidChangeSelectionAndFocus, onDidExpandItem/onDidCollapseItem, onDidChangeActions, onDidChangeWelcomeState — used by tree consumers and contributions (`treeView.ts:241-258`).

UI Flows & Behaviors
- Merge header: When single-view container merges, header visibility toggles and lastMergedCollapsedPane tracked to avoid jumping UI (`viewPaneContainer.ts:1066-1093`).
- Drag & drop of views & view containers: Dragging views/composites supports moving views between containers and reordering within container with overlay indicators (`viewPaneContainer.ts:424-511`, `:881-999`).
- Title actions & toolbars: ViewPane renders a WorkbenchToolBar with primary/secondary actions derived from ViewMenuActions; actions can be shown on hover, always, or when expanded (`viewPane.ts:446-466`, `:672-692`).
- Welcome content: Views can provide welcome content; ViewWelcomeController renders registered welcome descriptors and supports buttons that invoke commands or external links (`viewPane.ts:95-197`).
- Tree behaviors: custom async batching for getChildren, renderer with resource label and icons, checkbox cascade semantics, per-item context menus derived from MenuService with overlayed context keys (`treeView.ts:1173-1228`, `:1239-1250`, `:1240-1555`).

Descriptor & Registration Patterns
- Views contributed by extensions supply an ITreeView or view ctor through the ViewsRegistry → view descriptors stored in IViewDescriptorService. Host must implement registration surface that populates view descriptors and container models.
- Menu contribution patterns rely on context key overlays (view, viewItem, viewContainer, viewContainerLocation). The host must support MenuService or an adapter that can compute primary/secondary actions for a menu id+context. See [`viewMenuActions.ts:69-75`](src/vs/workbench/browser/parts/views/viewMenuActions.ts:69).

Porting Risks & Suggested Mitigations
1) Dynamic Instantiation & DI
- Risk: InstantiationService/SyncDescriptor patterns require DI / ctor descriptor resolution. Host without full DI must either provide a lightweight instantiation shim or pre-create instances.
- Mitigation: Implement a minimal InstantiationService adapter that can map registered ctor identifiers to host factory functions. See usage in [`viewPaneContainer.ts:createView:686`](src/vs/workbench/browser/parts/views/viewPaneContainer.ts:686).

2) Menu / ContextKey Engine
- Risk: MenuRegistry/MenuService and context key evaluation are central to deriving actions. Missing engine breaks most action/toolbars.
- Mitigation: Provide MenuService adapter that accepts menuId+context overlay and returns actions (primary/secondary). Implement ContextKey service or map to host predicate functions. See [`viewMenuActions.ts:29`](src/vs/workbench/browser/parts/views/viewMenuActions.ts:29).

3) Drag & Drop semantics & native DnD APIs
- Risk: Complex DnD flows (CustomTreeViewDragAndDrop) depend on dataTransfer types, extension-provided mime types, cross-window transfer via temporary drag operations (`treeView.ts:1819-2004`).
- Mitigation: Implement TreeViewsDndService adapter to broker additional transfer payloads and cancel tokens; provide limited no-op fallback that disables advanced DnD but keeps basic file/resource transfer.

4) Extension activation model
- Risk: activateByEvent('onView:...') expectations mean extensions expect host to call activation hooks. Without this, extension-contributed views won't populate.
- Mitigation: Provide an ExtensionService shim that can activate extensions or notify the extension runtime when a view becomes visible. See [`treeView.ts:1793-1799`](src/vs/workbench/browser/parts/views/treeView.ts:1793).

5) Theming & Icon resolution
- Risk: Theme service & file icon themes used for icons and CSS rules. Missing support results in broken icons/layout.
- Mitigation: Implement ThemeService adapter exposing color/theme and fileIconTheme metadata and simple fallback icons. See [`viewPane.ts:517-538`](src/vs/workbench/browser/parts/views/viewPane.ts:517).

Adapter / Shim Suggestions (host-side)
- InstantiationAdapter: map ctor descriptors to factories.
- MenuAdapter: resolve MenuId + context -> primary/secondary IAction list (id, title, icon, command).
- ContextKeyAdapter: evaluate context key expressions and allow binding keys for menus.
- TreeViewsDndService: broker extended drag transfers for extensions.
- ExtensionActivationAdapter: activateByEvent hook.
- ThemeAdapter: expose color and file icon theme support.

Tests & QA
- Unit tests: view container add/remove, pane size save/restore, isViewMergedWithContainer edge cases, menu extraction for primary/secondary actions.
- Integration tests: extension-provided tree view activation and welcome content rendering; drag & drop move/reorder flows in viewlets.
- Smoke tests: show/hide container, focus events, keyboard keybindings (move view up/down left/right) (`viewPaneContainer.ts:1212-1274`).

Implementation Callouts (important code locations)
- Pane/container orchestration: [`src/vs/workbench/browser/parts/views/viewPaneContainer.ts:291`](src/vs/workbench/browser/parts/views/viewPaneContainer.ts:291)
- View pane header, welcome controller, toolbar: [`src/vs/workbench/browser/parts/views/viewPane.ts:306`](src/vs/workbench/browser/parts/views/viewPane.ts:306)
- Viewlet filtering & constant descriptors: [`src/vs/workbench/browser/parts/views/viewsViewlet.ts:26`](src/vs/workbench/browser/parts/views/viewsViewlet.ts:26)
- Tree rendering, DnD, menus: [`src/vs/workbench/browser/parts/views/treeView.ts:81`](src/vs/workbench/browser/parts/views/treeView.ts:81)
- Menu action helpers: [`src/vs/workbench/browser/parts/views/viewMenuActions.ts:14`](src/vs/workbench/browser/parts/views/viewMenuActions.ts:14)

Quick Porting Checklist (workbench views)
- [ ] Provide InstantiationAdapter
- [ ] Provide MenuAdapter + ContextKeyAdapter
- [ ] Implement minimal ThemeAdapter and FileIcon mapping
- [ ] Implement TreeViewsDndService (or safe fallback)
- [ ] Wire ExtensionActivationAdapter to extension runtime
- [ ] Add unit tests for container/pane lifecycles

Conclusion
- The Workbench views & viewlet subsystem is modular: model-driven descriptors, DI-instantiated views, and menu/context-driven actions. Porting requires adapters around DI, menus/context keys, extension activation, DnD, and theming. Prioritize Menu + ContextKey + Instantiation adapters to unlock most UI behavior; DnD and extension activation are next priority for extension-provided views.

References
- ViewPaneContainer source: [`src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1`](src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1)
- ViewPane source: [`src/vs/workbench/browser/parts/views/viewPane.ts:1`](src/vs/workbench/browser/parts/views/viewPane.ts:1)
- Views viewlet: [`src/vs/workbench/browser/parts/views/viewsViewlet.ts:1`](src/vs/workbench/browser/parts/views/viewsViewlet.ts:1)
- Tree view implementation: [`src/vs/workbench/browser/parts/views/treeView.ts:1`](src/vs/workbench/browser/parts/views/treeView.ts:1)
- View menu helpers: [`src/vs/workbench/browser/parts/views/viewMenuActions.ts:1`](src/vs/workbench/browser/parts/views/viewMenuActions.ts:1)
