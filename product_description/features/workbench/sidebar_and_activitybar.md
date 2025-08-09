Workbench — Sidebar & Activity Bar

Overview
The Sidebar (aka primary side bar / viewlet area) and Activity Bar together manage the primary navigation surface for VS Code: view containers (explorer, search, scm, extensions, etc.), pinned/visible viewlets, activity badges, and the compact/expanded placements (title, top, bottom, hidden). This doc summarizes implementation responsibilities, key components, configuration, lifecycle, porting risks and adapter recommendations.

Key source files
- [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:36`] SidebarPart (extends AbstractPaneCompositePart) — main implementation for sidebar behavior and composite bar integration.
- [`src/vs/workbench/browser/parts/sidebar/sidebarActions.ts:18`] Sidebar actions registrations (close/focus, toggle activity bar visibility).
- [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:1`] ActivitybarPart (referenced by SidebarPart — activity bar host; see composite bar usage).
- [`src/vs/workbench/browser/parts/paneCompositePart.ts:1`] Pane composite base (behaviors shared by sidebar/panel/titlebar composites).

Note: the SidebarPart composes an ActivityBarCompositeBar when the activity bar is placed in the title area or as top/bottom.

Responsibilities
- Manage view container lifecycle (creation, activation, visibility, pinned/placeholder state).
- Host the composite bar for the side (title/top/bottom modes) or delegate to ActivitybarPart when the activity bar is visible.
- Provide sizing, preferredWidth heuristics and snap behavior for layout.
- Apply theming to sidebar and activity bar surfaces (colors, borders, drag-and-drop outlines).
- Persist the active viewlet id and activity bar position via IStorageService.
- Provide actions: close sidebar, focus into sidebar, toggle activity bar visibility (keybindings / commands).

Public APIs / Contracts
- Pane composite lifecycle methods from AbstractPaneCompositePart (getActivePaneComposite, focusCompositeBar, getPinnedPaneCompositeIds, etc.) used by layout & pane services.
- Configuration keys driving behavior:
  - LayoutSettings.ACTIVITY_BAR_LOCATION controls composite bar position (title/top/bottom/hidden).
  - Sidebar persisted key: 'workbench.sidebar.activeviewletid' (SidebarPart.activeViewletSettingsKey).
- Registered Actions:
  - 'workbench.action.closeSidebar' (close primary side bar) — [`src/vs/workbench/browser/parts/sidebar/sidebarActions.ts:18`]
  - 'workbench.action.focusSideBar' (focus into primary side bar, Ctrl/Cmd+0) — [`src/vs/workbench/browser/parts/sidebar/sidebarActions.ts:35`]

UI Components & Lifecycle
- SidebarPart (class):
  - Preferred width is driven by active viewlet's getOptimalWidth(); enforces a min width and a 300px lower bound when compute returns a number. See [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:50`].
  - Creates a composite bar via ActivityBarCompositeBar when appropriate, otherwise delegates activity to ActivitybarPart (instantiated via IInstantiationService).
  - Listens for configuration changes to ActivityBarPosition and updates composite bar and activityBarPart visibility (`onDidChangeActivityBarLocation`).
  - Exposes focusActivityBar() to bring activity bar into view or create it if hidden.
- ActivityBarCompositeBar:
  - Renders icons for view containers; supports hover behavior, overflow, sizes, badge colors and drag & drop border styles. Options configured in getCompositeBarOptions (colors, sizes, orientation, hover position) — see [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:170`].
- ActivitybarPart:
  - Used when activity bar should be shown as a standalone part (left/right). Sidebar delegates pinned/visible IDs to activityBarPart when composite bar is not used (`getPinnedPaneCompositeIds`, `getVisiblePaneCompositeIds`, `getPaneCompositeIds`).

Configuration & Theming
- Theme tokens used by the sidebar/activitybar surfaces:
  - SIDE_BAR_BACKGROUND, SIDE_BAR_FOREGROUND, SIDE_BAR_BORDER, SIDE_BAR_TITLE_FOREGROUND, ACTIVITY_BAR_* tokens for badges/active colors; applied in updateStyles — see [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:135`].
- Activity bar placement options:
  - CompositeBarPosition.TITLE (default), TOP, BOTTOM, HIDDEN are chosen based on LayoutSettings.ACTIVITY_BAR_LOCATION (value read and persisted).
- When ActivityBarLocation is TOP or BOTTOM, the composite bar replaces the activity bar and the sidebar shows the composite bar in that location.

Persistence & State
- Active viewlet id is persisted under SidebarPart.activeViewletSettingsKey ('workbench.sidebar.activeviewletid').
- Activity bar location is persisted to StorageScope.PROFILE when visible (rememberActivityBarVisiblePosition) and restored for toggling hidden/visible states.

Interaction Flows
- Toggle Activity Bar Visibility:
  - Registered action toggles LayoutSettings.ACTIVITY_BAR_LOCATION between HIDDEN and last-remembered visible position (`rememberActivityBarVisiblePosition` and `getRememberedActivityBarVisiblePosition`) — [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:232`].
- Focus into Sidebar:
  - The FocusSideBarAction ensures the sidebar is visible via IWorkbenchLayoutService and focuses the active viewlet via IPaneCompositePartService — see [`src/vs/workbench/browser/parts/sidebar/sidebarActions.ts:51`].
- Activity Bar location change:
  - on configuration change, SidebarPart hides activityBarPart, updates composite bar, re-shows activityBarPart if appropriate, and fires title area updates to ensure chrome reflects the active composite — see [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:118`].

Porting Considerations / Risks
- Composite bar widget:
  - The ActivityBarCompositeBar provides a compact composite toolbar that can live in multiple locations. Porting hosts must implement or adapt a composite-bar widget with similar APIs (icon rendering, overflow, hover actions, badges, drag/drop borders).
- View container model & extensions:
  - The sidebar depends on ViewDescriptorService and extension activation for view registration; hosts need an adapter to register and query view descriptors and visibility/persistence behavior.
- Layout coordination:
  - Interactions with IWorkbenchLayoutService (visibility toggling and part hiding) are central. Host layout service must implement equivalent part visibility APIs and part IDs (Parts.SIDEBAR_PART, Parts.ACTIVITYBAR_PART).
- StorageService usage:
  - The sidebar persists user preferences to storage (profile scope). Hosts need to honor storage scopes or map to their own persistence.
- Drag & Drop styling and hit-target calculations:
  - Composite bar options include dragAndDrop visuals; host must support drag overlays or provide graceful degradation.
- Accessibility & keyboard focus:
  - Focus actions (Ctrl/Cmd+0) and composite bar keyboard navigation need to be supported or mapped to host keybinding systems.

Suggested Adapter Surface
- CompositeBarAdapter:
  - createCompositeBar(options) → CompositeBar instance supporting setActions, focus, show/hide, layout(dimension).
  - Events for onDidChange (actions changed), onDidVisibilityChange.
- ActivityBarAdapter:
  - fall-back standalone activity bar part with APIs to return pinned/visible composite ids and show/hide behavior.
- ViewDescriptorAdapter:
  - enumerate, getActiveViewContainer(), getViewContainerById(), and lifecycle hooks for when view registrations change.
- LayoutAdapter:
  - setPartHidden(partId, hidden), isVisible(partId), getSideBarPosition(), setPartHidden, setPartWidth/height, parts enum for mapping.
- StorageAdapter:
  - store(key, value, scope), get(key, scope), remove(key, scope).
- KeybindingAdapter:
  - registerKeybinding(actionId, keybindingSpec), lookupKeybinding.
- ThemeAdapter:
  - provide theme tokens used by sidebar and activity bar or mapping hooks.

Tests and Validation
- Unit tests:
  - preferredWidth calculation when active viewlet returns different optimal widths.
  - composite bar option construction: verify colors, sizes and hover positioning options are wired properly.
  - toggle activity bar visibility commands persist and restore remembered positions.
- Integration tests:
  - Changing LayoutSettings.ACTIVITY_BAR_LOCATION from TITLE→TOP→HIDDEN should cause appropriate part creation/hide and restore previously selected viewlet when re-enabled.
  - FocusSideBarAction should show part and focus active viewlet (simulate layout service + pane composite service).
  - Ensure storage persistence of active viewlet and activity bar position across simulated restarts.

Implementation Notes
- SidebarPart delegates to ActivitybarPart for many lists when the composite bar isn't used; port should respect this delegation model to avoid duplicating logic.
- Composite bar "compact" mode and icon sizing are configured via getCompositeBarOptions(). Ensure host composite supports icon sizes and overflow behaviors.
- When activity bar is placed in title area (CompositeBarPosition.TITLE), additional context menu actions are inserted (`fillExtraContextMenuActions` in options). Host should support injecting submenu actions into the composite overflow.
- The activity bar may be hidden; focusActivityBar() toggles the configuration and forces layout updates.

Next Steps
- Create TypeScript shim examples for CompositeBarAdapter and LayoutAdapter under src/adapters/ to guide host implementers.
- Add unit test skeletons for preferredWidth and toggle activity bar behavior.
- Continue synthesizing any related activitybar implementation files (read activitybarPart.ts) to capture pinned/placeholder keys and deeper behavior.

Cross-references
- Sidebar implementation: [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:36`]
- Sidebar actions: [`src/vs/workbench/browser/parts/sidebar/sidebarActions.ts:18`]
- Composite & activity bar interfaces (referenced): [`src/vs/workbench/browser/parts/paneCompositePart.ts:1`], [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:1`]

Document created from: [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:1`], [`src/vs/workbench/browser/parts/sidebar/sidebarActions.ts:1`].
