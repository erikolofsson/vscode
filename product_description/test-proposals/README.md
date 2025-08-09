Test Proposals — Workbench UI

Overview
This directory contains test skeletons and integration scenarios for workbench UI components we documented. Each proposal describes purpose, required mocks/adapters, setup steps, and assertions to validate behavior during porting.

Tests index
- Activity Bar lifecycle and behaviors — product_description/test-proposals/activitybar.md:1
- Window Title template tests — product_description/test-proposals/window_title.md:1
- CompositeBar adapter smoke tests — product_description/test-proposals/composite_bar_adapter.md:1
- Sidebar focus and toggle tests — product_description/test-proposals/sidebar.md:1

Guidance
Each test file should include:
- Purpose, Setup (mocks/adapters), Steps, Assertions, References

References
- Activity bar source: [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:42`](src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:42)
- Titlebar source: [`src/vs/workbench/browser/parts/titlebar/titlebarPart.ts:220`](src/vs/workbench/browser/parts/titlebar/titlebarPart.ts:220)
- Sidebar source: [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:36`](src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:36)
- Adapter guide: [`product_description/features/workbench/adapter_guides.md:1`](product_description/features/workbench/adapter_guides.md:1)

Recommended test harness
- Unit: Jest + jsdom for DOM-level behavior
- Integration: Playwright for end-to-end UI flows

Next steps
- Create the per-test markdown skeleton files listed above.
