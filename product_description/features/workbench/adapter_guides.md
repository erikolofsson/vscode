Workbench — Adapter guide (titlebar, sidebar, activity bar)

Purpose
This document records recommended adapter interfaces, responsibilities, and mapping notes for components we analyzed in the workbench: titlebar & menubar, sidebar & composite bar, and activity bar. Hosts that want to port VS Code UI features should implement these adapter surfaces (or equivalent) in their environment. This guide focuses on documentation (no TypeScript shims) and references the original source files.

Core principles
- Keep adapters small and focused: expose only the lifecycle and data the workbench parts need.
- Provide change events so the workbench code can subscribe and react.
- Provide test doubles (mocks) for unit tests to validate wiring without a full UI.
- Map theme tokens to host theme system or provide a ThemeAdapter returning colors.

Primary adapter surfaces (overview)
- CompositeBarAdapter — composite icon/tool bar used for title/top/bottom activity bars and the activity bar.
- LayoutAdapter — layout service surface used to query and set part visibility and sidebar position.
- MenuAdapter — menu registry / menu service surface to provide grouped actions for MenuId values.
- ContextKeyAdapter — simple context key store used to evaluate ContextKeyExpr-driven visibility/toggled state.
- ViewDescriptorAdapter — view container registry / view descriptor surface for enumerating and activating view containers.
- ThemeAdapter — mapping from theme tokens (TITLE_BAR_*, SIDE_BAR_*, ACTIVITY_BAR_*) to color values.

Why adapters (summary)
The workbench parts depend on platform services and registries (IMenuService, IContextKeyService, IWorkbenchLayoutService, IViewDescriptorService, IThemeService). During a host port, these heavy subsystems are often absent or different. Implementing adapters avoids changing core workbench logic while allowing the host to provide equivalent behavior.

Adapter details

1) CompositeBarAdapter
- Purpose: Provide a small API for rendering a composite (row/column of icon actions) used by:
  - [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:166`]
  - [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:72`]
  - Titlebar composite usages via PaneCompositeBar.
- Required surface:
  - create(container: HTMLElement, options: { orientation, iconSize, compact, colors, activityHoverOptions, fillExtraContextMenuActions, compositeSize, overflowActionSize }): CompositeBar
  - CompositeBar:
    - setActions(primary: Action[], secondary?: Action[]): void
    - focus(index?: number): void
    - show(): void
    - hide(): void
    - layout(width: number, height: number): void
    - getPinnedPaneCompositeIds(): string[]
    - getVisiblePaneCompositeIds(): string[]
    - getPaneCompositeIds(): string[]
    - dispose(): void
    - onDidChange(listener): () => void
- Notes:
  - Colors callback must accept a theme object and return mapped colors used for badges, active/inactive foreground, drag-and-drop border (see [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:88`]).
  - fillExtraContextMenuActions allows injection of extra context menu items when the composite sits in alternative locations (title/top).

2) LayoutAdapter
- Purpose: Provide minimal layout APIs used by parts to hide/show parts and get/set sidebar position:
  - References: [`src/vs/workbench/browser/parts/titlebar/titlebarPart.ts:26`], [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:8`]
- Required surface:
  - setPartHidden(partId: string, hidden: boolean): void
  - isVisible(partId: string): boolean
  - focusPart(partId: string): void (optional but used by focus actions)
  - getSideBarPosition(): 'left' | 'right' | 'default'
  - setSideBarPosition(position: 'left'|'right'|'default'): void
  - onDidChange(listener): () => void
- Persistence:
  - Hosts should persist activity bar location and active viewlet ids in a profile/workspace store equivalent to IStorageService (keys referenced in source: `workbench.activity.*`, `workbench.sidebar.activeviewletid`).

3) MenuAdapter
- Purpose: Provide menu action groups for MenuId values consumed by menubars and titlebar toolbars.
  - References: [`src/vs/workbench/browser/parts/titlebar/menubarControl.ts:48`], [`src/vs/workbench/browser/parts/titlebar/titlebarPart.ts:27`]
- Required surface:
  - createMenu(menuId: string, contextKeyService?, options?): Menu
  - Menu:
    - getActions(options?): [group, IAction[]][]
    - onDidChange(listener): () => void
    - dispose(): void
- Notes:
  - Must support submenu structures and support retrieval with shouldForwardArgs and renderShortTitle flags where used.
  - MenuAdapter must be able to supply both primary/secondary splits for action bars (WorkbenToolBar usage).

4) ContextKeyAdapter
- Purpose: Support evaluation of context expressions used by action/menu visibility and toggled state (ContextKeyExpr).
  - References: [`src/vs/workbench/browser/parts/titlebar/titlebarActions.ts:12`], experiments with IsCompactTitleBarContext and TitleBarVisibleContext.
- Required surface:
  - setContext(key: string, value: any)
  - getContext(key: string): any
  - onDidChange(listener(keysChanged: string[]))
  - evaluate(expression): boolean (optional; host can provide evaluation or workbench can evaluate against key/values)
- Notes:
  - For hosts that can't evaluate the full ContextKeyExpr language, provide a minimal evaluator (equals, notEquals, has, boolean negation) sufficient for workbench expressions.

5) ViewDescriptorAdapter
- Purpose: Expose registered view containers (viewlets/panels), pinned/view states and activation hooks used by the sidebar and activity bar.
  - References: [`src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1`], [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:23`]
- Required surface:
  - enumerateViewContainers(): ViewContainerDescriptor[]
  - getActiveViewContainer(): string | undefined
  - setActiveViewContainer(id: string): void
  - onDidChangeContainers(listener): () => void
  - optionally: activateViewById(id) to trigger extension activation hooks
- Notes:
  - The adapter should notify when extension-contributed views become available (extensions may register views lazily).

6) ThemeAdapter
- Purpose: Map theme tokens used by parts into concrete color values for the host.
  - Token examples: TITLE_BAR_ACTIVE_BACKGROUND, SIDE_BAR_BACKGROUND, ACTIVITY_BAR_BADGE_BACKGROUND.
- Required surface:
  - getColor(token: string): string | undefined
  - onDidChangeTheme(listener): () => void
- Notes:
  - ThemeAdapter can be implemented by asking the host theme engine for color values, or by providing a mapping from token names to CSS variables.

Testing & mocks (documentation approach)
- Instead of providing code shims in the repository, document mock behavior and expected API traces for test teams:
  - CompositeBar mock should record create/layout/setActions calls and expose a simple DOM rendering to test keyboard navigation.
  - MenuAdapter mock should return deterministic action groups used in title/toolbars tests.
  - LayoutAdapter mock should allow toggling visibility and emitting onDidChange events to simulate user configuration changes.

Cross-references (source anchors)
- Titlebar primary: [`src/vs/workbench/browser/parts/titlebar/titlebarPart.ts:220`]
- Titlebar menubar & actions: [`src/vs/workbench/browser/parts/titlebar/menubarControl.ts:129`], [`src/vs/workbench/browser/parts/titlebar/titlebarActions.ts:20`]
- Sidebar implementation: [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:36`]
- Activity bar implementation: [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:42`]
- PaneCompositeBar base: [`src/vs/workbench/browser/parts/paneCompositeBar.ts:1`]

Porting notes / risks (summary)
- Menus & ContextKeys are core: missing implementations cause many actions and toolbars to appear empty; prioritize MenuAdapter + ContextKeyAdapter.
- Drag & drop and DnD brokering across extensions is complex; host implementations may choose to provide basic drag visuals first and defer extension DnD.
- Theme tokens: ensure opaque backgrounds for titlebar to preserve font LCD rendering (see TITLE_BAR_ACTIVE_BACKGROUND handling).
- Persistence: replicate StorageScope semantics (profile vs machine) or map to the host preferences store.

Next steps (recommended, docs-first, no code)
1. For each adapter in this document, create a one-page spec in product_description/features/workbench/adapters/ with:
   - API signature (documented)
   - Example usage from the workbench source (file anchors)
   - Mock behavior for tests
2. Create product_description/test-proposals/ entries that reference these adapters and list the tests that rely on them (unit and integration).
3. Maintain documentation-only artifacts — do not add new runtime code to the source tree unless hosts request example code.

Document produced from repository analysis and source reads (anchors above).
