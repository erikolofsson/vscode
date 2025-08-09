Workbench — Titlebar & Menubar

Overview
This document summarizes responsibilities, key components, UI flows, porting risks and adapter recommendations for VS Code's titlebar / menubar area. It synthesizes behavior found in the Titlebar parts and related menubar control.

Key source files
- [`src/vs/workbench/browser/parts/titlebar/titlebarPart.ts:220`] Main implementations: BrowserTitlebarPart, MainBrowserTitlebarPart, AuxiliaryBrowserTitlebarPart.
- [`src/vs/workbench/browser/parts/titlebar/windowTitle.ts:53`] Window title template, variables, and native document.title sync.
- [`src/vs/workbench/browser/parts/titlebar/menubarControl.ts:129`] Custom menubar implementation (CustomMenubarControl, MenubarControl).
- [`src/vs/workbench/browser/parts/titlebar/titlebarActions.ts:20`] Titlebar-related actions and menu registrations.
- Sidebar cross references: [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:1`], [`src/vs/workbench/browser/parts/sidebar/sidebarActions.ts:1`].

Responsibilities
- Render the window title area and optional custom menu bar.
- Expose a per-window title service: title variables registration and properties update (via BrowserTitleService).
- Host action toolbars and activity/account tiles in the titlebar.
- Integrate with layout and configuration to show/hide menubar, command center, window controls and editor actions.
- Provide context-menu handling for the title area and title text.

Public APIs / Contracts
- ITitleService / BrowserTitleService (creates main + auxiliary titlebar parts) — see [`src/vs/workbench/browser/parts/titlebar/titlebarPart.ts:88`].
- registerWindowTitleVariable command: 'registerWindowTitleVariable' (registered in BrowserTitleService) — see [`src/vs/workbench/browser/parts/titlebar/titlebarPart.ts:135`].
- MenuIds used: MenuId.TitleBarContext, MenuId.TitleBarTitleContext, MenuId.TitleBar, MenuId.LayoutControlMenu, Menubar menus registered in [`src/vs/workbench/browser/parts/titlebar/menubarControl.ts:48`].

Important Context Keys & Settings
- IsCompactTitleBarContext, TitleBarVisibleContext, TitleBarStyleContext — used throughout [`src/vs/workbench/browser/parts/titlebar/*`].
- window.customTitleBar visibility and MenuSettings.MenuBarVisibility config drive menubar installation/uninstallation.
- LayoutSettings.LAYOUT_ACTIONS, LayoutSettings.COMMAND_CENTER, activity bar location influence action placement and visibility.

UI Components & Lifecycle
- BrowserTitlebarPart (view part) provides createContentArea, layout, updateStyles, focus, dispose — see [`src/vs/workbench/browser/parts/titlebar/titlebarPart.ts:220`].
- WindowTitle builds title string from template variables, listens to editor/service events and updates document.title — see [`src/vs/workbench/browser/parts/titlebar/windowTitle.ts:216`].
- CustomMenubarControl renders a MenuBar UI using base MenuBar component and drives menu actions; it reacts to config changes, recently opened, update service and keybindings — see [`src/vs/workbench/browser/parts/titlebar/menubarControl.ts:404`].
- Titlebar action toolbar is a WorkbenchToolBar instance hosting editor-global actions, layout actions and activity tiles; it composes its menus via IMenuService (MenuId.TitleBar, MenuId.LayoutControlMenu).

Interaction Flows
- Menubar visibility: installation/uninstallation logic in createContentArea / installMenubar / uninstallMenubar and on configuration changes (`titlebarPart` lines ~407–424).
- Context menu: right-click on rootContainer opens either TitleBarContext or TitleBarTitleContext depending on OS and click target (`onContextMenu` in `titlebarPart`).
- Command Center replacement for text title when enabled (instantiates CommandCenterControl) — see createTitle (`titlebarPart` lines ~576–581).
- Editor action migration: editor group supplies editor-specific actions that are integrated into the title toolbar (createActionToolBarMenus).
- Menubar updates: CustomMenubarControl observes menus and calls setupCustomMenubar/update to rebuild menu structure and actions.

Styling & Theming
- Titlebar uses theme tokens: TITLE_BAR_ACTIVE_BACKGROUND, TITLE_BAR_ACTIVE_FOREGROUND, TITLE_BAR_BORDER, WORKBENCH_BACKGROUND for opaque composition (`updateStyles` in `titlebarPart`).
- Titlebar applies 'light' CSS class when background is light; uses --zoom-factor CSS variable to coordinate zoom prevention behavior.

Persistence & State
- Stores preferences for menu visibility and editor action last location via IStorageService (see `titlebarActions.ts` and storage usage in `titlebarPart`).
- Recently opened lists (menubar) are fetched from IWorkspacesService and updated when window focus changes (see `menubarControl`).

Porting Considerations / Risks
- Menu subsystem: heavy use of MenuRegistry, IMenuService, MenuId enums and MenuBar UI component — host must provide a MenuAdapter and MenuBar UI or a simplified replacement. See [`src/vs/workbench/browser/parts/titlebar/menubarControl.ts:27`].
- ContextKey evaluation: visibility and toggled state (ContextKeyExpr) drive many menu entries and actions. Provide a ContextKeyAdapter that can evaluate expressions and expose context changes.
- Instantiation & custom action view items: titlebar instantiates CommandCenterControl, WorkbenchToolBar and activity action items via IInstantiationService. Provide InstantiationAdapter and ActionViewItemFactory to map to host components.
- Host window integration: HostService is used to detect focus changes and open windows; menubar includes operations that call hostService.openWindow. Provide HostAdapter to bridge window operations and focus events.
- Accessibility & platform specifics: macOS, Web, Native differences are sprinkled across code (menu mnemonics, window controls location, WCO). Ensure platform flags and accessibility APIs are available or polyfilled.
- Zoom prevention & layout coordination: titlebar computes minimum heights, zoom factors and uses layout service sizing; ensure the host layout service implements required APIs (`IWorkbenchLayoutService`).

Suggested Adapter Surface
- MenuAdapter: createMenu(menuId, contextKeyService, options) → returns menu actions and subscriptions.
- MenubarUIAdapter: a thin wrapper for base MenuBar widget or alternative, supporting updateMenu / push / toggleFocus / onVisibilityChange.
- ContextKeyAdapter: evaluate expressions, bind context keys, emit onDidChange events.
- InstantiationAdapter: ability to create instances of controls like CommandCenterControl, WorkbenchToolBar, and action view items.
- HostAdapter: focus events, openWindow, showContextMenu fallback.
- ThemeAdapter: expose color tokens or map them to host theme values.

Implementation Notes
- When menubar is 'compact' it can be rendered in the activity bar (see `menubarControl.get currentCompactMenuMode`).
- The title text is updated asynchronously and pushes the native document.title — ensure WindowTitle.doUpdateTitle updates host window title similarly.
- The titlebar respects 'native titlebar' settings and will avoid rendering window control container or menu if native titlebar is active (`hasNativeTitlebar` checks).

Tests and Validation
- Unit tests:
  - title template expansion with variables and separators — use [`src/vs/workbench/browser/parts/titlebar/windowTitle.ts:216`] as reference.
  - menubar menu-to-action mapping and recent items injection — test `CustomMenubarControl.setupCustomMenubar`.
  - toolbar action composition: editor actions, layout actions, global actions and activity tiles.
- Integration tests:
  - Simulate config changes for MenuBarVisibility and verify install/uninstall of the custom menubar.
  - Focus/blur window events toggle 'inactive' styles and update document.title appropriately.

Porting Checklist (minimal MVP)
- [ ] Provide MenuAdapter that can supply menu action lists for MenuId values used by titlebar.
- [ ] Provide ContextKeyAdapter with basic expressions used by titlebar actions.
- [ ] Provide InstantiationAdapter to construct CommandCenterControl and WorkbenchToolBar.
- [ ] Provide HostAdapter for openWindow and focus events.
- [ ] Implement ThemeAdapter to map TITLE_BAR_* tokens.
- [ ] Provide simplified MenubarUI component or map to host menu control.

Cross-References
- Titlebar implementation: [`src/vs/workbench/browser/parts/titlebar/titlebarPart.ts:220`]
- Titlebar actions registration: [`src/vs/workbench/browser/parts/titlebar/titlebarActions.ts:20`]
- Menubar & Menu registration: [`src/vs/workbench/browser/parts/titlebar/menubarControl.ts:48`]
- Window title templating and variables: [`src/vs/workbench/browser/parts/titlebar/windowTitle.ts:53`]
- Sidebar integration: [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:1`]

Next steps
- Create a short adapter implementation guide with example TypeScript shims for MenuAdapter and ContextKeyAdapter.
- Implement unit tests for WindowTitle template handling.
- Continue with Sidebar & Activity Bar detailed synthesis (read sidebar files if not already done) and write product_description/features/workbench/sidebar_and_activitybar.md.

Document created from files read: [`src/vs/workbench/browser/parts/titlebar/titlebarPart.ts:1`], [`src/vs/workbench/browser/parts/titlebar/menubarControl.ts:1`], [`src/vs/workbench/browser/parts/titlebar/windowTitle.ts:1`], [`src/vs/workbench/browser/parts/titlebar/titlebarActions.ts:1`].
