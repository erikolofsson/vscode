# Workbench — Titlebar, Activity Bar, Auxiliary Bar & Pane Composite Bar

Summary

This document synthesizes responsibilities, lifecycles, public APIs, UI flows, persistence, theming, DnD, accessibility and porting notes for titlebar, activity bar, auxiliary bar and pane composite bar subsystems.

Related source files

- [`src/vs/workbench/browser/parts/titlebar/titlebarPart.ts:1`]
- [`src/vs/workbench/browser/parts/auxiliarybar/auxiliaryBarPart.ts:1`]
- [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:1`]
- [`src/vs/workbench/browser/parts/paneCompositeBar.ts:1`]
- [`src/vs/workbench/browser/parts/paneCompositePart.ts:1`]

Responsibilities

- Titlebar: window title composition, custom menubar, command center, activity/global toolbars, window controls and per-window auxiliary titlebars.
- Activity Bar: primary vertical/compact composite holder for view containers (pinned/visible), menu integration and keyboard navigation.
- Auxiliary Bar: a secondary side location for composites mirroring sidebar behavior but with distinct config keys and placement logic.
- Pane Composite Bar: composable composite bar used by ActivityBar, Sidebar, Panel and Auxiliary parts; caching, persistence, pin/placeholder semantics, DnD and composite actions.
- Pane Composite Part: manages lifecycle of pane composites (view containers) and wires pane-specific toolbar, header/footer composite bars and empty pane DnD behavior.

Lifecycles & instantiation

- All parts are constructed via DI / InstantiationService and registered with layout and lifecycle services. Example creators:
  - Titlebar service → [`src/vs/workbench/browser/parts/titlebar/titlebarPart.ts:1`]
  - ActivityBarPart created as part of workbench parts → [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:1`]
  - PaneCompositeBar created per-part by PaneCompositePart → [`src/vs/workbench/browser/parts/paneCompositePart.ts:1`]

- create() → render DOM containers, wire toolbars/menus/menubar, register listeners
- layout(width,height,top,left) → compute sizes and lay out internal composite bars, toolbar widths and overlay areas
- saveState/restore → use IStorageService for pinned/placeholder/workspace keys
- dispose() → remove listeners, DOM nodes, and disposable stores

Public APIs & important interactions

- PaneCompositePart exposes host-facing APIs (openPaneComposite / getActivePaneComposite / getPaneComposites / getProgressIndicator / hideActivePaneComposite). See [`src/vs/workbench/browser/parts/paneCompositePart.ts:1`]
- ActivitybarPart exposes list accessors: getPinnedPaneCompositeIds(), getVisiblePaneCompositeIds(), focus(), layout()
- PaneCompositeBar / CompositeBar: API for adding/removing/computing composite items, pin/unpin and dnd handlers. See [`src/vs/workbench/browser/parts/paneCompositeBar.ts:1`]

Key UI flows & behaviors

- Title composition and toolbars:
  - Titlebar composes window title, optional command center, menubar and a WorkbenchToolBar of actions. Global activity actions (Manage / Accounts) are rendered as small activity view items in the title. See [`src/vs/workbench/browser/parts/titlebar/titlebarPart.ts:1`].
  - Menubar visibility modes (compact/toggle/hidden) influence whether a custom menubar is created in the titlebar or activitybar.

- Activity bar and global actions:
  - ActivitybarPart creates an ActivityBarCompositeBar with options (iconSize, compositeSize, colors) and optionally a GlobalCompositeBar for Manage/Accounts, driven by configuration and storage keys. See [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:1`].
  - Keyboard navigation binds menu <-> activity icons <-> global actions and accounts.

- Pane composite placement & header/footer bars:
  - AbstractPaneCompositePart chooses a CompositeBarPosition (TOP / TITLE / BOTTOM) based on part type and configuration. PaneCompositePart creates PaneCompositeBar instances with location-aware options. See [`src/vs/workbench/browser/parts/paneCompositePart.ts:1`].
  - When composite bar is TITLE, it blends into the title area and affects available toolbar width; compositeBar layout considers toolbar width.

- Auxiliary bar:
  - Mirrors sidebar behaviors but reads `workbench.secondarySideBar.showLabels` and stores pinned/placeholder keys separate from primary activity keys. See [`src/vs/workbench/browser/parts/auxiliarybar/auxiliaryBarPart.ts:1`]

Drag & Drop semantics

- Composite and view DnD are centralized via CompositeDragAndDrop / CompositeDragAndDropObserver:
  - PaneCompositeBar constructs a CompositeDragAndDrop handler that delegates open/move semantics to the PaneCompositePart (openPaneComposite and compositeBar.move). See [`src/vs/workbench/browser/parts/paneCompositeBar.ts:1`].
  - ViewPaneContainer / PaneCompositePart also register DnD targets for panes and the empty pane area; overlays use ViewPaneDropOverlay and toggleDropEffect to set dataTransfer.effect. See [`src/vs/workbench/browser/parts/paneCompositePart.ts:1`].

- Drop behavior supports moving single views, whole composites and anchor-based reordering using Before2D insertion indices.

Persistence & important storage keys

- Activity/Composite pinned placeholders (profile/machine/workspace scopes):
  - Activitybar: `workbench.activity.pinnedViewlets2`, `workbench.activity.placeholderViewlets`, `workbench.activity.viewletsWorkspaceState` — see Activitybar constants in [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:1`]
  - PaneCompositeBar options accept pinned/placeholder/workspace-storage keys via IPaneCompositeBarOptions
  - AuxiliaryBar uses its own keys: `workbench.auxiliarybar.pinnedPanels`, `workbench.auxiliarybar.placeholderPanels`, `workbench.auxiliarybar.viewContainersWorkspaceState` in [`src/vs/workbench/browser/parts/auxiliarybar/auxiliaryBarPart.ts:1`]

- Titlebar menubar visibility and remembered state is read from configuration and stored via IStorageService events. See titlebar menubar handling: [`src/vs/workbench/browser/parts/titlebar/titlebarPart.ts:1`]

Theming

- Composite bars and activity elements obtain colors from theme tokens (ACTIVITY_BAR_*, SIDE_BAR_*, PANEL_* tokens). PaneCompositeBar accepts a colors callback that drives dynamic CSS rules for URI icons via createCSSRule; ThemeIcon classNames are used for theme icons. See [`src/vs/workbench/browser/parts/paneCompositeBar.ts:1`].
- Titlebar uses TITLE_BAR_ACTIVE/INACTIVE tokens and computes opaque backgrounds to avoid LCD text rendering artifacts.

Accessibility & keyboard navigation

- Menu / activity / titlebar focus interplay is explicitly wired:
  - Titlebar toolbars and activity global actions provide keyboard handlers for Enter/Space and arrow keys (`registerKeyboardNavigationListeners` in ActivityBarCompositeBar). See [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:1`].
- Focus contexts and context keys:
  - Parts set context keys for active composite and focus (ActiveAuxiliaryContext, SidebarFocusContext, Pane focus etc.), enabling keybindings to be scoped correctly. See AbstractPaneCompositePart wiring in [`src/vs/workbench/browser/parts/paneCompositePart.ts:1`].

Performance & UX patterns to preserve

- Lazy menu resolution: build heavy menus/toolbars after LifecyclePhase.Restored or when idle (used in GlobalCompositeBar/Accounts initialization).
- Cache and restore composite state: PaneCompositeBar caches pinned/placeholder/workspace state and merges with runtime registrations to avoid UI jumps before extensions register.
- Avoid layout thrash: only recompute composite bar sizes when necessary and compute toolbar width before layouting composite bar in PaneCompositePart.

Porting notes & adapter considerations

- Provide minimal implementations for:
  - StorageAdapter (get/set with PROFILE/WORKSPACE/MACHINE support)
  - MenuService/Menu creation (deferred evaluation of menu actions)
  - ActivityAdapter (get activities, onDidChangeActivity)
  - DnDAdapter (toggleDropEffect, registerDraggable/registerTarget)
  - Titlebar host integration for window controls and menubar visibility

- Styling: port must recreate CSS token system and dynamic CSS rule generation for URI-based icons (createCSSRule/asCSSUrl).
- Accessibility: retain ARIA behaviors and keyboard navigation ordering between menu, activity icons and global actions.

Tests to propose

- Composite bar persistence: pin/unpin, placeholder state and ordering survive reload; test pinnedViewContainers and placeholder keys.
- DnD overlay and Move semantics: drop a 'view' and a 'composite' to a PaneCompositePart and assert viewDescriptorService.moveViewsToContainer invoked and pane order updated (Before2D handling).
- Titlebar menubar modes: switching MenuSettings.MenuBarVisibility updates menubar installation and layout (compact vs hidden vs default).
- Keyboard focus chain: menubar -> activity bar -> global composite -> composite items using arrow keys and Enter triggers.

Recommended next steps

1. Draft TypeScript shim examples that implement StorageAdapter and DnDAdapter under `product_description/src_adapters/` to unblock host integration work.
2. Author unit/integration tests proposals under `product_description/tests_proposals/workbench/` covering the test cases above.
3. Continue iterating across the rest of Workbench parts in ~5-file batches and update MANIFEST and OVERVIEW cross-links as new docs appear.

Cross-links

- Composite & Activity bar deep-dive: [`product_description/features/workbench/composites_and_activitybar.md:1`]
- Sidebar / Panel & Views: [`product_description/features/workbench/sidebar_panel_and_views.md:1`]
- Host adapter contracts: [`product_description/src_adapters/workbench_adapters.md:1`]

End of document.
