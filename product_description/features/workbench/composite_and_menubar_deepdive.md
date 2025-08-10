# Workbench — Composite Bar, Composite Actions, Global Composite Bar & Menubar Control

Summary

This doc synthesizes responsibilities, models, interaction patterns, drag & drop, overflow, badges, menus and menubar control for the composite bar family and the global/menubar UI pieces.

Related source files

- [`src/vs/workbench/browser/parts/globalCompositeBar.ts:1`](src/vs/workbench/browser/parts/globalCompositeBar.ts:1)
- [`src/vs/workbench/browser/parts/compositeBar.ts:1`](src/vs/workbench/browser/parts/compositeBar.ts:1)
- [`src/vs/workbench/browser/parts/compositeBarActions.ts:1`](src/vs/workbench/browser/parts/compositeBarActions.ts:1)
- [`src/vs/workbench/browser/parts/compositePart.ts:1`](src/vs/workbench/browser/parts/compositePart.ts:1)
- [`src/vs/workbench/browser/parts/titlebar/menubarControl.ts:1`](src/vs/workbench/browser/parts/titlebar/menubarControl.ts:1)

Responsibilities

- CompositeBar: manage visible/pinned composites, compute sizes, overflow, render action bar and provide DnD hooks.
- CompositeBarAction / CompositeBarActionViewItem: encapsulate per-composite actions, badges and interaction.
- PaneCompositeBar: part-specific wrapper producing CompositeBar instances with location-aware options (see paneCompositeBar).
- GlobalCompositeBar: small vertical bar for global actions (Manage / Accounts / profile badge) shown alongside activity/composite bars.
- MenubarControl / CustomMenubarControl: build the native-like application menu, wire MenuRegistry menus into a MenuBar, support compact mode and accessibility.

Data structures and models

- ICompositeBarItem / ICompositeBarModelItem: canonical items tracked by CompositeBarModel (id, name, pinned, order, visible).
- CompositeBarModel: authoritative list of items, active item, and helper methods (add, remove, move, pin, activate).
- CompositeBar maintains compositeSizeInBar map used to compute visibility/overflow based on available space.

Key algorithms and behaviors

- Overflow computation:
  - Compute size per composite (from CSS size or configured compositeSize).
  - Build list of candidates: pinned items + active composite.
  - Add candidates until limit reached (width or height based on orientation).
  - Ensure active composite is always shown if possible; if overflowed, include overflow action.
  - When overflowing, an overflow CompositeOverflowActivityAction and view item show a menu of extra composites.

- Reordering / Move semantics:
  - move(from, to, before) adjusts model ordering and forces the moved item to become pinned.
  - CompositeDragAndDrop abstracts drop handling: handles 'composite' and 'view' drag types and delegates to viewDescriptorService and the paneCompositePart open/move APIs.

- Badges & Activities:
  - Activities are provided via IActivity; CompositeBarAction stores activities and emits onDidChangeActivity.
  - Badges rendered by CompositeBarActionViewItem determine type (progress, number, icon) and compute display/legend.
  - Badge enablement is persisted and toggled via viewDescriptorService.setViewContainerBadgeEnablementState.

Drag & Drop specifics

- CompositeDragAndDrop.onDragEnter/onDragOver return whether drop is allowed; drop() executes different flows for 'composite' vs 'view'.
- Drop target index computation uses Before2D insertion hints (verticallyBefore/horizontallyBefore) and orientation-specific logic.
- CompositeBar and CompositeActionViewItem use CompositeDragAndDropObserver to register draggable/targets and provide visual feedback classes (top/bottom/left/right).
- PaneCompositePart and CompositeBarDndCallbacks coordinate to allow dropping into empty pane areas and to move views between containers.

GlobalCompositeBar & accounts/profile

- GlobalCompositeBar renders two primary action view items: GLOBAL_ACTIVITY_ID and ACCOUNTS_ACTIVITY_ID; Accounts visibility is a profile preference `workbench.activity.showAccounts`.
- AccountsActivityActionViewItem groups accounts by provider, populates hierarchical submenu actions and supports sign out/manage flows; initialization is deferred until LifecyclePhase.Restored and idle.
- GlobalActivityActionViewItem shows profile badge (initials) when non-default profile and no activity badges are present.

Menubar control & menu wiring

- MenubarControl constructs MenuBar from MenuRegistry Menus, maps top-level titles and creates IMenu instances for submenus.
- CustomMenubarControl supports compact mode (activity-bar integrated menubar), mnemonics, accessibility toggles, and dynamic insertion (recent workspaces/files, update actions).
- Menu updates are scheduled (RunOnceScheduler) and avoid updates while the menubar is focused to preserve focus-related context keys.
- Options like enableMnemonics, disableAltFocus, visibility and compactMode are provided to the MenuBar renderer.

CompositePart — lifecycle & instantiation

- CompositePart manages instantiation of composites from a CompositeRegistry and caches created composite instances and their DOM containers.
- createComposite instantiates descriptor via instantiationService in a child service collection to provide composite-scoped services (e.g., IEditorProgressService).
- showComposite handles DOM insertion, sets toolbar/action runner, layout, progress scope and visibility; hideActiveComposite removes from DOM and stops progress.
- CompositePart stores last active composite id in storageService (workspace scope) and reads it on construction.

Actions / Toolbars / Context menus

- WorkbenchToolBar is used for per-composite actions; CompositePart.collectCompositeActions assembles primary/secondary actions and wiring.
- CompositeBar exposes getContextMenuActions() to produce pin/unpin actions and uses options.fillExtraContextMenuActions to allow part-specific items.
- CompositeActionViewItem builds context menus with toggle pin/badge actions and extra actions from composite-specific providers.

Theming & icon handling

- CompositeBar and CompositeBarActionViewItem use ICompositeBarColors callbacks to style active/inactive foregrounds, borders and badge colors.
- URI-based icons are converted to CSS mask rules via createCSSRule/asCSSUrl in paneCompositeBar (note: look at paneCompositeBar for CSS generation).
- ThemeIcon class names are used for codicon/theme-based icons.

Accessibility & keyboard navigation

- CompositeBar action list exposes role='tablist' and each item role='tab'; Composite overflow menu provides accessible selection semantics.
- MenubarControl configures mnemonics and focuses via Alt+F10 (web) or platform-specific sequences; CustomMenubarControl coordinates focus/visibility and accessibility notifications.
- Focus contexts and ARIA attributes are maintained by CompositeActionViewItem.updateChecked/updateTitle.

Persistence & storage keys

- Composite/pinning persistence keys are provided by PaneCompositeBar options (pinnedViewContainersKey, placeholderViewContainersKey, viewContainersWorkspaceStateKey) and stored via IStorageService in profile/workspace scopes.
- Accounts visibility is stored under `workbench.activity.showAccounts` as profile-level preference; GlobalCompositeBar queries via storageService.

Porting and adapter notes

- Provide adapters for:
  - MenuService: createMenu/menu actions resolution with deferred evaluation.
  - StorageAdapter: support get/store with scopes PROFILE/WORKSPACE and events for onDidChangeValue.
  - ActivityService: provide getActivity/getViewContainerActivities and onDidChangeActivity.
  - PaneCompositePartService / ViewDescriptorService: openPaneComposite, moveViewContainerToLocation, moveViewsToContainer and view container metadata.
  - DnD primitives: registerDraggable/registerTarget, toggleDropEffect.
- Ensure child instantiationService semantics: Composite instantiation occurs with a child services collection to provide composite-scoped IEditorProgressService.
- Recreate CSS dynamic rule generation for uri icons (createCSSRule) when porting to hosts without CSSOM support.

Test proposals

- Overflow algorithm: create composites with known CSS sizes, set container dimension, assert visibleComposites and overflow menu contents.
- DnD behaviors:
  - Drag composite within same bar -> verify move() invoked and model order changed.
  - Drag composite across bars -> verify viewDescriptorService.moveViewContainerToLocation invoked and paneCompositePart.openPaneComposite called.
  - Drag view into empty pane area -> verify viewDescriptorService.moveViewToLocation and that composite opens and view is focused.
- Badge rendering: verify progress/number/icon badges types render expected DOM changes and badge enablement toggles persist.
- Menubar: verify compact mode rendering, recent menu population and that RunOnceScheduler batching prevents spurious updates while focused.

Recommended next steps

1. Create adapter-contract stubs for MenuService, ActivityService and StorageAdapter under [`product_description/src_adapters/workbench_adapters.md:1`](product_description/src_adapters/workbench_adapters.md:1) (if not already done).
2. Add unit tests under `product_description/tests_proposals/workbench/` for overflow, DnD and badges.
3. Continue reviewing adjacent parts that call into these modules (paneCompositeBar, paneCompositePart, activitybarPart) and add cross-links (many already created).

Cross-links

- Composite & Activity bar deep-dive: [`product_description/features/workbench/composites_and_activitybar.md:1`](product_description/features/workbench/composites_and_activitybar.md:1)
- Pane Composite & Parts: [`product_description/features/workbench/titlebar_activity_auxiliary_and_panecomposites.md:1`](product_description/features/workbench/titlebar_activity_auxiliary_and_panecomposites.md:1)

End of document.
