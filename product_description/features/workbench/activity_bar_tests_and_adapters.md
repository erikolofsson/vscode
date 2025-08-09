Workbench — Activity Bar tests & adapter proposals

Overview
This document lists unit/integration test proposals and adapter proposal details to validate porting of the Activity Bar component (icons, badges, drag & drop, pinned placeholders).

References
- Activity Bar implementation: [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:42`](src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:42)
- Pane composite base: [`src/vs/workbench/browser/parts/paneCompositeBar.ts:1`](src/vs/workbench/browser/parts/paneCompositeBar.ts:1)
- Titlebar menubar integration: [`src/vs/workbench/browser/parts/titlebar/menubarControl.ts:404`](src/vs/workbench/browser/parts/titlebar/menubarControl.ts:404)

Goals
- Define deterministic unit tests for ActivitybarPart behaviors.
- Define integration tests exercising composite-bar + layout + menu interactions.
- Provide adapter interface proposals and concrete mock behaviors hosts can implement for testing.

Unit test proposals
1. Composite creation lifecycle
- Purpose: ensure ActivitybarPart creates the composite bar lazily on show() and disposes on hide().
- Setup: instantiate a test ActivitybarPart with a mocked IPaneCompositePart and IInstantiationService that returns a mock PaneCompositeBar with spies for create/layout/dispose.
- Assertions:
  - Before show(): compositeBar is undefined.
  - After show(): compositeBar.create called with content element.
  - After hide(): compositeBar.dispose (or clear) called and content cleared.

2. Theme color propagation
- Purpose: verify colors callback maps tokens to composite options.
- Setup: provide a fake IColorTheme that returns specific hex values for tokens used (e.g. ACTIVITY_BAR_BADGE_BACKGROUND).
- Assertions:
  - The PaneCompositeBar.options.colors(theme) returns expected values.

3. Preferred sizes & layout call
- Purpose: ensure ActivitybarPart.layout delegates to compositeBar.layout with computed content size.
- Setup: provide a mock compositeBar with a layout spy.
- Assertions:
  - layout(width,height) calls compositeBar.layout with width and content height.

4. Keyboard navigation wiring
- Purpose: arrow keys move focus between menubar (when compact), activity icons, and global composite items.
- Setup: render the menubarContainer and compositeBarContainer in DOM, attach keydown events.
- Assertions:
  - Pressing Right/Down opens focus into composite bar.
  - Pressing Left/Up moves focus back to menubar when present.

5. Activity context menu composition
- Purpose: verify getActivityBarContextMenuActions returns expected submenu actions (position, toggle visibility).
- Setup: mock menuService.getMenuActions to return specific actions and assert returned array includes ToggleSidebarPosition action.
- Assertions:
  - Context menu contains ToggleSidebarPositionAction and (if part===SIDEBAR) ToggleSidebarVisibilityAction.

Integration test proposals
1. Placement transitions (title -> top -> hidden)
- Purpose: ensure switching LayoutSettings.ACTIVITY_BAR_LOCATION updates composite vs standalone activity bar and restores pinned items.
- Setup: run with real PaneCompositeBar implementation (or faithful mock) and change configuration values, observe calls to create/hide, and storage reads/writes for pinned lists.
- Assertions:
  - On TOP: composite bar created in sidebar composite area.
  - On HIDDEN: activitybarPart.hide() invoked; remembered position persisted.

2. Drag & drop visual behavior
- Purpose: simulate a drag operation over activity icons and verify dragAndDropBorder color is applied to the composite options or DOM overlay.
- Setup: use DOM-driven compositeBar; synthesize dragenter/dragover events.
- Assertions:
  - Drag overlay or border is presented and matches configured theme color.

3. Badge updates & concurrency
- Purpose: validate badge updates from different sources (extension decorations, service updates) are rendered and do not race.
- Setup: fire multiple badge update events asynchronously.
- Assertions:
  - Final badge state matches last committed update; no UI thrash or crashes.

Adapter proposals (design & mock behaviors)
- CompositeBarAdapter (reference): interface that supports create(container, options) => { setActions, focus, show, hide, layout, getPinnedPaneCompositeIds, getVisiblePaneCompositeIds, dispose }.
  - Mock: a DOM-based shim that records calls (create/layout/setActions) and exposes synchronous spies for tests. See prototype at [`src/adapters/compositeBarAdapter.ts:58`](src/adapters/compositeBarAdapter.ts:58).
- LayoutAdapter: minimal layout API for setPartHidden/isVisible/getSideBarPosition/setSideBarPosition and onDidChange.
  - Mock: InMemoryLayoutAdapter stores state and emits change events for tests. See [`src/adapters/layoutAdapter.ts:16`](src/adapters/layoutAdapter.ts:16).
- MenuAdapter: createMenu(menuId) => Menu with getActions(), onDidChange()
  - Mock: SimpleInMemoryMenu used in tests to inject action groups. See [`src/adapters/menuAdapter.ts:1`](src/adapters/menuAdapter.ts:1).
- ContextKeyAdapter: provide get/set context keys for evaluating ContextKeyExpr during menu action resolution.
  - Mock: InMemoryContextKeyAdapter in [`src/adapters/contextKeyAdapter.ts:1`](src/adapters/contextKeyAdapter.ts:1).
- ViewDescriptorAdapter: abstract interface to enumerate view containers and simulate extension-provided registrations.
  - Mock: Provide an in-memory registry allowing tests to register/unregister view containers and simulate activation events.

Test harness recommendations
- Use a browser-like DOM test runner (Jest + jsdom or Playwright for integration scenarios).
- Provide lightweight dependency injection replacing IInstantiationService, IStorageService, IMenuService and IThemeService with test doubles.
- Where full implementations are heavy, use DOM shims (e.g. compositeBarAdapter) to test rendering and keyboard flows.

Prioritization & effort estimates
- High: Lifecycle & persistence tests (2–3 days) — critical to ensure UI wiring and restore behavior.
- Medium: Keyboard navigation and context menu mapping (1–2 days).
- Low: Drag & drop visual fidelity and race conditions (2–4 days) — more effort due to async and DOM interactions.

Next steps
1. Create test skeleton files under [`product_description/test-proposals/activitybar/`](product_description/test-proposals/activitybar/:1) mapping the unit/integration cases above.
2. Deliver minimal mock adapters (DOM shims) in `product_description/tests/mocks/` so platform teams can run tests locally.
3. Run a QA pass of workbench docs and update MANIFEST (already updated).

Document author: automated code analysis — generated from [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:42`](src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:42)

End of document
