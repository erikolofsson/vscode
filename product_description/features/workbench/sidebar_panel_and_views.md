# Workbench — Sidebar, Panel & Views

Summary

This document describes responsibilities, lifecycles, public APIs, UI flows, data model, persistence, tests, and porting notes for the Workbench sidebar, panel and view container subsystems.

Related source files

- [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:1`]
- [`src/vs/workbench/browser/parts/panel/panelPart.ts:1`]
- [`src/vs/workbench/browser/parts/paneCompositePartService.ts:1`]
- [`src/vs/workbench/browser/parts/globalCompositeBar.ts:1`]
- [`src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1`]

Responsibilities

- Sidebar / Activity bar host: manage composite bars, activity bar placement (title/top/bottom), remembered visibility, theme styling and title area.
- Panel host: manage panel composites, position-aware layout, title/toolbar, panel-specific context menu and showLabels toggle.
- Global composite area: render global actions (Manage, Accounts), profile badging, account menus and activity badges.
- ViewPaneContainer: render a stacked/ split collection of ViewPane instances, handle pane layout, resizing, drag-and-drop, header visibility and merging single-view behavior.

Lifecycles

- Construction: parts are instantiated via the DI/InstantiationService. Example creation points:
  - SidebarPart constructed in [`src/vs/workbench/browser/parts/paneCompositePartService.ts:1`].
  - PanelPart and AuxiliaryBar are also instantiated there.
- create/render: parts create DOM containers and inner composite bars or PaneView instances (create → render).
- layout: parts expose layout(width,height,top,left) used by the workbench layout service.
- saveState/restore: parts persist limited state (active IDs, visible counts, sizes) via IStorageService.
- dispose: parts clean up listeners, DOM and disposable stores.

Public APIs & Events (host-facing)

- IPaneCompositePartService (implemented by `PaneCompositePartService`) — key methods:
  - openPaneComposite(id, location, focus?)
  - getActivePaneComposite(location)
  - getPaneComposites(location)
  - getPinnedPaneCompositeIds(location)
  - getVisiblePaneCompositeIds(location)
- ViewPaneContainer events:
  - onTitleAreaUpdate, onDidChangeVisibility, onDidAddViews, onDidRemoveViews, onDidChangeViewVisibility, onDidFocusView, onDidBlurView
  (see [`src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1`])

Key UI flows and behaviors

- Composite bar placement:
  - SidebarPart adapts composite bar position based on LayoutSettings.ACTIVITY_BAR_LOCATION (title/top/bottom/hidden) and remembers last visible position in storage (see `rememberActivityBarVisiblePosition`).
- Activity bar vs composite bar:
  - When composite bar is shown (top/bottom), it owns pinned/visible ids; otherwise the ActivityBarPart provides those lists.
- Focus and activation:
  - focusActivityBar toggles visibility and focuses appropriate bar; title area updates propagate via onTitleAreaUpdate.
- Global actions & accounts:
  - GlobalCompositeBar renders Manage and Accounts actions; accounts menu is dynamic and populated from IAuthenticationService; accounts visibility is persisted under `workbench.activity.showAccounts`.
- Views merging:
  - ViewPaneContainer can merge a single view with the container title (mergeViewWithContainerWhenSingleView option); headers and collapsible behavior are updated accordingly.
- Drag and Drop:
  - Composite and view DnD uses CompositeDragAndDropObserver; ViewPaneDropOverlay draws overlay zones and computes DropDirection (UP/DOWN/LEFT/RIGHT) and toggles dataTransfer dropEffect.
  - Moving views between containers updates viewDescriptorService and viewContainerModel (moveViewsToContainer, move).

Data model & persistence keys

- SidebarPart.activeViewletSettingsKey = 'workbench.sidebar.activeviewletid'
- PanelPart.activePanelSettingsKey = 'workbench.panelpart.activepanelid'
- ViewPaneContainer visible count key: `${containerId}.numberOfVisibleViews` (stored workspace/machine scope)
- Accounts visibility preference: `workbench.activity.showAccounts` (PROFILE scope)
- Composite pinned/placeholder/workspace keys referenced from ActivitybarPart (see related composite docs).

Theming & styling

- Parts declare theme tokens for background, foreground, borders and drag/drop backgrounds and use dynamic CSS variables when rendering headers, badges and drag overlays.
- GlobalCompositeBar and Activity bar use ThemeIcon classNames and dynamic badge colors driven by theme tokens.

Performance & UX patterns to preserve when porting

- Defer heavy menu resolution and account initialization until LifecyclePhase.Restored and idle (GlobalCompositeBar uses lifecycleService.when + runWhenWindowIdle).
- Avoid layout thrash: PaneView resize/restore and saveState are carefully scheduled (restore sizes on first layout, then save on sash changes).
- DnD overlays are short-lived and cleaned up on mouseover/timeouts to avoid blocking input (ViewPaneDropOverlay cleanup scheduler).

Porting notes and adapter recommendations

Core host adapters required (docs-only contracts to author next):

- PaneCompositePartServiceAdapter: exposes open/get/pinned/visible APIs for host to call into the workbench part manager.
- ViewDescriptorAdapter: enumerate container descriptors, view descriptors, moveViewsToContainer(viewIds[], destinationId, source) and query canMoveView.
- StorageAdapter: get/set scoped values (profile/workspace/machine) with boolean/number/string support.
- ActivityAdapter: activity counts and badges surface (getActivity(containerId) and onDidChangeActivity events).
- AuthenticationAdapter / AccountsAdapter: enumerate accounts, sessions, signOut flows, and onDidChangeSessions; expose initial embedded session info.
- DnDAdapter (small): provide dataTransfer behaviors for 'view' and 'composite' payloads and toggleDropEffect helper.

Implementation & integration risks

- Heavy DI: parts rely on many platform services (instantiationService, menuService, themeService, viewDescriptorService, storageService, layoutService). Porting must provide minimal implementations or shims that satisfy the methods used.
- Dynamic menus: view and panel context menus use MenuService/MenuId; port should provide a way to populate actions lazily and resolve action view items.
- Authentication, Profiles and MCP: Accounts and profile badge use product/auth/profile services; these can be stubbed for initial iterations.

Test proposals (unit/integration)

- DnD: simulate dragging a view from one container to another and assert viewDescriptorService.moveViewsToContainer called and ViewPaneContainer state updated; verify overlay appears and DropDirection handling moves anchor element correctly.
- Merge behavior: when only one view exists and mergeViewWithContainerWhenSingleView is true, verify title text and header visibility toggles and saved visibleViews count influences startup behavior.
- Composite bar position changes: toggle LayoutSettings.ACTIVITY_BAR_LOCATION and assert SidebarPart computed composite bar position and activityBar show/hide behavior and storage persistence.
- Accounts menu init: simulate authentication providers registered before/after initialization and assert accounts are populated and problematic providers are logged and re-tried.

Recommended next steps

1. Author adapter-contract docs under product_description/src_adapters for the adapters listed above.
2. Add the proposed tests to product_description/tests_proposals/workbench/ with mocks for viewDescriptorService and storageService.
3. Continue the 5-file read → synthesize → write cycle for remaining Workbench parts (titlebar, statusbar deep-dive tests, panels extras).

Notes / cross-links

- See the previously created composite & activity bar doc: [`product_description/features/workbench/composites_and_activitybar.md:1`]
- View pane DnD / overlay implementation: [`src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1`]

End of document.
