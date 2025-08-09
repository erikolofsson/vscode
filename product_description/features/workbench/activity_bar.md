Workbench — Activity Bar (icons, badges, drag & drop, pinned placeholders)

Overview
The Activity Bar is the primary vertical icon-based launcher for view containers (Explorer, Search, SCM, Extensions, etc.). It supports pinned/visible viewlets, badges, keyboard navigation, compact menubar integration, drag-and-drop cues and flexible placement (side, top, bottom). This doc synthesizes implementation details from the upstream code.

Primary source references
- Activity bar part implementation: [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:42`]
- PaneCompositeBar usage and options referenced by Activity bar: [`src/vs/workbench/browser/parts/paneCompositeBar.ts:1`]
- Titlebar/menubar integration for compact mode: [`src/vs/workbench/browser/parts/titlebar/menubarControl.ts:404`]

Responsibilities
- Render activity icons corresponding to registered view containers.
- Provide a compact/icon-only vertical bar with focus & keyboard navigation.
- Show badges (counts/notifications) and active state highlight for the selected view.
- Support drag-and-drop visuals and drop target borders.
- Support alternate placements: left/right sidebar (default), top or bottom (composite bar mode).
- Integrate an optional compact menubar when MenuBarVisibility == "compact".
- Persist pinned view container order and placeholders into workspace/profile storage keys.

Key behaviors & wiring
- ActivitybarPart class is the main entrypoint which constructs a PaneCompositeBar via createCompositeBar (see [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:72`]). The composite bar is configured with:
  - Orientation: vertical
  - Icon sizing: iconSize 24
  - compositeSize and overflowActionSize (configured values)
  - Theme color providers for active/inactive foreground, active border, badge background/foreground, drag/drop border (see colors callback at [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:88`]).
- Composite bar lifecycle:
  - Lazy creation in show(): `this.compositeBar.value = this.createCompositeBar()` and create(this.content) (`[`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:146`]`).
  - Cleared by hide(): `this.compositeBar.clear()` and content node cleared.
- Keyboard navigation:
  - Activity bar wires arrow keys to navigate between activity icons, supports Up/Down and Left/Right to move focus between menubar (compact) and activity icons (`[`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:293`]`).
- Menubar compact integration:
  - If the menubar config is 'compact', the ActivityBarCompositeBar installs a `CustomMenubarControl` at the top of the bar (`installMenubar()` / `uninstallMenubar()` in `ActivityBarCompositeBar`, [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:282`]).
- Context menu and activity actions:
  - Activity bar collects context menu actions and activity-specific submenu actions, e.g., ActivityBarPositionMenu and ToggleSidebar actions (`getActivityBarContextMenuActions()` at [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:369`]).

Theming & Styling
- Theme tokens used:
  - ACTIVITY_BAR_BACKGROUND, ACTIVITY_BAR_BORDER, ACTIVITY_BAR_FOREGROUND
  - ACTIVITY_BAR_ACTIVE_BORDER, ACTIVITY_BAR_ACTIVE_BACKGROUND
  - ACTIVITY_BAR_BADGE_BACKGROUND, ACTIVITY_BAR_BADGE_FOREGROUND
  - ACTIVITY_BAR_DRAG_AND_DROP_BORDER, ACTIVITY_BAR_ACTIVE_FOCUS_BORDER
- The part registers a theming participant to emit CSS rules for active borders, focus outlines, active background, etc. See theme rules registered at [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:547`].

Persistence & Keys
- Storage keys referenced for pinned/placeholder/workspace state:
  - `workbench.activity.pinnedViewlets2` (`ActivitybarPart.pinnedViewContainersKey`)
  - `workbench.activity.placeholderViewlets` (`ActivitybarPart.placeholderViewContainersKey`)
  - `workbench.activity.viewletsWorkspaceState` (`ActivitybarPart.viewContainersWorkspaceStateKey`)
  These are wired into the PaneCompositeBar options when the ActivityBarCompositeBar is created (`[`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:73`])

Drag & Drop & Badges
- Drag & drop:
  - Drag visuals and drop borders are driven by the composite bar's color options, specifically the dragAndDropBorder token, and the composite bar draws outlines or border accents when items are dragged over (`colors(...)` callback at [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:88`]).
- Badges:
  - Each activity action can display a badge; the composite bar maps badge background/foreground colors from theme tokens into its rendering.

APIs & Contracts (for host adapters)
- PaneCompositeBar-like API:
  - create(container), layout(width,height), focus(), getPinnedPaneCompositeIds(), getVisiblePaneCompositeIds(), getPaneCompositeIds(), setActions / setItems.
  - Hosts should provide an adapter that supports similar lifecycle and APIs used by ActivitybarPart.
- Menu integration:
  - IMenuService and MenuId.ActivityBarPositionMenu are used; a MenuAdapter must provide getActions and onDidChange for menus consumed by `getActivityBarContextMenuActions()`.
- ViewDescriptorService / ViewsService:
  - Activity bar expects a view container model and view registration lifecycle via IViewDescriptorService and IViewsService.

Porting considerations & risks
- Composite bar widget complexity:
  - The composite bar has a lot of features (overflow, pinned placeholders, drag/drop, badges, keyboard nav). Porting hosts need either:
    - A faithful composite-bar widget (recommended), or
    - A simplified implementation that covers MVP features (icons, click-to-activate, simple badges, keyboard focus) and defers advanced features.
- Menu & ContextKey integrations:
  - ContextKey expressions and MenuService are used to compose context menus. Hosts need to provide a MenuAdapter and ContextKeyAdapter.
- Accessibility and keyboard flows:
  - Arrow-key semantics and focus movement between menubar and activity icons need careful testing on each platform and input modality (touch, keyboard).
- Theming:
  - Hosts must map theme tokens to their theme engine or provide a ThemeAdapter for token values.
- Storage & persistence:
  - Storage keys are persisted to IStorageService; hosts should map to equivalent profile/workspace storage.

Suggested Adapter surfaces (shims)
- CompositeBarAdapter (already provided shim at [`src/adapters/compositeBarAdapter.ts:58`])
  - createCompositeBar(container, options) => { setActions, focus, show, hide, layout, onDidChange }
- LayoutAdapter (reference at [`src/adapters/layoutAdapter.ts:16`])
  - setPartHidden(partId, hidden), isVisible(partId), getSideBarPosition(), setSideBarPosition(), onDidChange
- MenuAdapter (reference at [`src/adapters/menuAdapter.ts:1`])
  - createMenu(menuId) => Menu with getActions, onDidChange
- ViewDescriptorAdapter
  - enumerate view containers, provide events when new view containers are registered (extensions), and provide pinned/visible state accessors.

Tests & Validation
- Unit tests:
  - Verify composite bar is created lazily on show() and cleared on hide().
  - Verify theme tokens are passed into composite colors (activeForeground/ badge colors).
  - Verify getActivityBarContextMenuActions returns ToggleSidebarPosition and ToggleSidebarVisibility items based on part id.
- Integration tests:
  - Change LayoutSettings.ACTIVITY_BAR_LOCATION from title -> top -> hidden and validate composite bar vs activitybarPart visibility and pinned IDs flow.
  - Keyboard navigation: Up/Down, Left/Right transitions between menubar (compact) and activity icons.
  - Drag & drop: simulate drag-over and assert dragAndDropBorder style gets applied.

Implementation notes & hints
- The ActivityBarCompositeBar extends PaneCompositeBar and reuses a lot of pane/composite logic (pinning, placeholder items, overflow). When porting, reuse existing pane-composite code where possible or provide a compatible adapter surface.
- Menu compactness: When the menu setting is 'compact', ActivityBarCompositeBar will install a menubar DOM inside the activity bar (see `installMenubar()`).
- Global activities: The activity bar can host a GlobalCompositeBar for global actions; this is optional (ActivityBarCompositeBar conditionally constructs `GlobalCompositeBar`).

Cross-references
- Activitybar main implementation: [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:42`]
- Composite bar base & pane composite APIs: [`src/vs/workbench/browser/parts/paneCompositeBar.ts:1`]
- Titlebar compact menubar integration: [`src/vs/workbench/browser/parts/titlebar/menubarControl.ts:404`]

Next steps
- If desired, I will:
  - Produce adapter shims for ViewDescriptorAdapter and ContextKeyAdapter.
  - Add unit test skeletons for activity bar behaviors under product_description/test-proposals/.
  - Continue to the Panel/Statusbar deeper dives.
