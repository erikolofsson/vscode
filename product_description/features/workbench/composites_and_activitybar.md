# Workbench — Composites, Pane Composites & Activity Bar

Summary

The Composite subsystem coordinates collection of view containers (composites) and the bars that host them (CompositeBar, PaneCompositeBar) and delivers the Activity Bar (primary vertical icon bar). This doc synthesizes responsibilities, lifecycle, layout, DnD, theming, and porting notes.

Responsibilities

- Host and render composites (view containers / pane composites) and manage active/pinned/visible state.
- Provide composite bars that compute available space, overflow handling, pinning, ordering, context menus and activity badges.
- Provide pane-specific wiring (sidebar, panel, auxiliary), persistence of pinned/placeholder state and workspace visibility.
- Provide the Activity Bar as the primary navigation surface with optional compact menubar and global activities.

Key components (implementation)

- CompositeBar — composite switcher and overflow handling; sizing, drag-and-drop hooks and action view item creation. See [`src/vs/workbench/browser/parts/compositeBar.ts:1`].
- CompositePart — base Part for composites, creates title area, toolbars and manages composite lifecycle and actions. See [`src/vs/workbench/browser/parts/compositePart.ts:1`].
- PaneCompositeBar — pane-specific bar wiring, caching of view container state, persistence keys and storage integration. See [`src/vs/workbench/browser/parts/paneCompositeBar.ts:1`].
- AbstractPaneCompositePart / PaneCompositePart — composition for sidebar/panel/auxiliary parts, title/header/footer placement of composite bars, empty-pane drop target handling, and open/hide semantics. See [`src/vs/workbench/browser/parts/paneCompositePart.ts:1`].
- ActivitybarPart — top-level Activity Bar part, installs ActivityBarCompositeBar, menubar integration, theme participants and keyboard navigation. See [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:1`].

Model & state

- Composite items: id, name, pinned, visible, order. Model tracked in CompositeBarModel (in-memory).
- Active composite: one active item at a time; activation/deactivation causes show/hide and toolbar/action update.
- Persistence: pinned/placeholder lists and workspace visibility are persisted using IStorageService under keys managed by PaneCompositeBar options.

Layout & sizing rules

- CompositeBar computes per-composite sizes (css-measured or fixed option) and determines how many items fit in available width/height; adds overflow action when necessary.
- PaneCompositeBar respects placement (TOP / TITLE / BOTTOM) via CompositeBarPosition and creates/removes DOM containers accordingly.
- Activity Bar is a vertical composite bar with fixed compositeSize and overflowActionSize; layout subtracts menubar/global activity areas when present.

Drag & Drop

- CompositeDragAndDrop implements drop semantics for composites and views; supports moving view containers between locations and opening moved views.
- CompositeDragAndDropObserver registers targets and draggable sources; pane empty-area supports dropping to create new containers.
- Drop feedback toggled with toggleDropEffect; DnD callbacks determine insertion index using Before2D.

Actions, context menus & menus

- Composite actions are represented by CompositeBarAction and related ActionViewItems (CompositeActionViewItem, CompositeOverflowActivityActionViewItem).
- Right-click context menus on composite bars expose pin toggles, move actions (to sidebar/panel/auxiliary) and additional actions from options.fillExtraContextMenuActions.
- Pane title areas include a MenuWorkbenchToolBar for global actions and per-composite toolbars are routed through CompositePart.toolBar.

Theming & tokens

- Activity and composite bars consume theme colors for foreground, active border, badge colors and drag/drop border. See theme tokens in ActivityBar implementation (ACTIVITY_BAR_*). See [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:1`].

Accessibility & keyboard

- Action bars expose aria labels (activityBarAriaLabel) and support focus navigation and loop-prevention options.
- ActivityBar and global composite bars register keyboard listeners to navigate between menu, activity icons and global activities.

Persistence & extension registration

- PaneCompositeBar caches view containers, placeholder metadata, and workspace visibility; it relies on extension registration lifecycle to reconcile built-in vs contributed containers.
- Storage keys are configurable via options (pinnedViewContainersKey, placeholderViewContainersKey, viewContainersWorkspaceStateKey).

Porting notes & adapter guidance

- Required host contracts:
  - ViewDescriptorService adapter to enumerate containers, move view/container locations, query container models and default containers.
  - Storage adapter matching IStorageService semantics (PROFILE/WORKSPACE scopes).
  - Menu/Action bar primitives (ActionBar, WorkbenchToolBar, Dropdowns) or thin shims that can render action toolbars.
  - DnD helper utilities including drag data, drop effect toggling and hit-testing (Before2D).

- Important UI behaviors to preserve:
  - Overflow computation and overflow action behavior (including pinned/active item visibility guarantees).
  - Pin/unpin semantics and "default composite" fallback when active composite removed.
  - Pane empty-area drop behavior that allows converting a dropped view into a new container opened in the pane.

Tests (suggested)

- Unit:
  - CompositeBar overflow and size computation with variable composite sizes.
  - Pin/unpin persistence round-trip through storage keys.
  - Drag-and-drop: moving composites between bars and opening moved views.

- Integration/UI:
  - Activity Bar keyboard navigation with compact menubar and global activities.
  - PaneComposite position permutations (TOP/TITLE/BOTTOM) and associated layout/resizing.

Related source files

- [`src/vs/workbench/browser/parts/compositeBar.ts:1`]
- [`src/vs/workbench/browser/parts/compositePart.ts:1`]
- [`src/vs/workbench/browser/parts/paneCompositeBar.ts:1`]
- [`src/vs/workbench/browser/parts/paneCompositePart.ts:1`]
- [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:1`]

Next steps

- Author adapter interface docs (ViewDescriptorAdapter, StorageAdapter, ActionBarAdapter, DnDAdapter) in product_description/src_adapters for host implementers.
- Add detailed test plans and small example of persisted JSON layout for pinned/placeholder state.

End.
