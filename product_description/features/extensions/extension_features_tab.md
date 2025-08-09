# Feature: Extensions — Extension Features Tab

Summary
- Short name: Extension Features Tab
- Purpose: Present a per-extension view of contributed "features" (privacy/telemetry/proxy-like features) such as runtime status, access data, charts, and allow enabling/revoking access where applicable. The view composes renderers (table, markdown, element) contributed by feature descriptors and uses the Extension Features Registry to discover feature providers.

Representative source files
- Main implementation: [`src/vs/workbench/contrib/extensions/browser/extensionFeaturesTab.ts`](src/vs/workbench/contrib/extensions/browser/extensionFeaturesTab.ts:1)
- Supporting registries and descriptors:
  - Features registry types: [`src/vs/workbench/services/extensionManagement/common/extensionFeatures.ts`](src/vs/workbench/services/extensionManagement/common/extensionFeatures.ts:1)
  - Extension management / access data service: [`src/vs/workbench/services/extensionManagement/common/extensionFeaturesManagementService.ts`](src/vs/workbench/services/extensionManagement/common/extensionFeaturesManagementService.ts:1) (implementation elsewhere)
- UI primitives:
  - List component: [`src/vs/platform/list/browser/listService.ts`](src/vs/platform/list/browser/listService.ts:1)
  - Markdown renderer: [`src/vs/base/browser/markdownRenderer.ts`](src/vs/base/browser/markdownRenderer.ts:1)
  - Chart rendering helpers (SVG): implemented inline in the feature renderer

Responsibilities
- Discover extension features via the Features Registry and determine which should render for a given extension manifest.
- Render a split view:
  - Left: list of features for the extension
  - Right: feature view with renderer output (table, markdown, markdown+table, element)
- Support runtime status feature showing activation, access counts, errors/messages and provide a small chart showing requests over the last 30 days
- Allow toggling access for features that are configurable (confirmation dialog + setEnablement)
- Render dynamic content that can update via onDidChange events exposed by renderer outputs

UI/UX details
- Uses a horizontal SplitView:
  - Left pane: WorkbenchList of IExtensionFeatureDescriptor
  - Right pane: Feature view container; renderer output is appended
- Feature list items show disabled state if feature is not enabled for the extension and a status icon indicating severity
- Feature view supports markdown rendering with theme icons and safe openerService usage
- Charts:
  - The runtimeStatus renderer draws a small SVG chart and uses hoverService to show tooltips for points
  - It computes counts per day and renders axis, gridlines, polyline, and an interactive highlight circle

Runtime boundaries & dependencies
- Renderer-side UI only (workbench)
- Relies on services:
  - IExtensionService (to determine if extension is installed/activated)
  - IInstantiationService (to instantiate registered renderers)
  - IExtensionFeaturesManagementService (access data, enablement, access times)
  - IOpenerService, IDialogService, IHoverService, IThemeService etc.
- Feature renderers are created via SyncDescriptor and instantiated with DI; renderers may subscribe to extension status or management service events and provide onDidChange updates

Data model
- IExtensionFeatureDescriptor: describes the feature id, label, access configuration, and renderer descriptor
- AccessData: contains accessTimes (Date[]), current status (severity + message), and other metadata exposed by the management service
- The runtime status renderer reads activationTimes and runtimeErrors from IExtensionService and accessData from IExtensionFeaturesManagementService

Public API / extension points
- Extensions can register features via the Extension Features Registry (Extensions.ExtensionFeaturesRegistry)
- A feature descriptor includes:
  - id, label, access metadata, renderer descriptor (table/markdown/element)
- Management service exposes:
  - getAccessData(extensionId, featureId)
  - setEnablement(extensionId, featureId, enabled)
  - onDidChangeAccessData, onDidChangeEnablement events

Security & UX considerations
- Markdown renderers can include trusted content (isTrusted) — openerService calls use allowCommands: true when allowed by the renderer
- Enabling/revoking access is gated by a confirmation dialog to prevent accidental permission grant/revoke

Porting notes — high level
- Pluggable renderer model:
  - Maintain an extensible renderer registry (table/markdown/markdown+table/element) and a DI/instantiation mechanism for renderer instances
- Dynamic updates:
  - Renderers provide onDidChange event to notify the view to re-render content when data changes; ensure target platform supports subscription & disposal patterns
- Charting:
  - The runtime status chart is hand-coded SVG with hover interactions; port as plain SVG or adopt a small charting helper with equivalent interaction hooks
- Dialogs & confirmation:
  - DialogService is used to confirm enable/revoke; ensure the ported platform exposes a modal confirmation API

Tests & QA mapping
- Unit tests for:
  - Renderer instantiation logic and shouldRender checks
  - Button toggle flow (confirmation + setEnablement)
  - Chart rendering logic (e.g., points calculation) can be covered by unit tests if the computation is extracted
- Integration tests:
  - Simulate extension activation and verify runtime status updates and chart updates
  - Verify enabling/revoking access persists via the management service

Per-feature porting checklist (see template)
- Required reads:
  - [`src/vs/workbench/contrib/extensions/browser/extensionFeaturesTab.ts`](src/vs/workbench/contrib/extensions/browser/extensionFeaturesTab.ts:1)
  - Registry & feature descriptor types in extension management services
  - Management service interface and implementation points
- High-level steps:
  1. Implement extension features registry and management service API in the port
  2. Implement renderer instantiation and lifecycle (onDidChange, dispose)
  3. Port markdown renderer and action handlers (openerService)
  4. Port confirmation dialog flows and enablement toggles
  5. Implement chart rendering & hover interactions
  6. Add tests mapping renderer and enablement flows

Open questions for deeper pass
1. Are there additional features registered via extensions in `extensions/` that rely on this registry? (Scan `extensions/` for `extensionFeatures` usage)
2. Does any renderer expect server-side resources or heavy native modules?
3. Where is the management service persisted or what backing stores are used for enablement state?

References
- Implementation: [`src/vs/workbench/contrib/extensions/browser/extensionFeaturesTab.ts`](src/vs/workbench/contrib/extensions/browser/extensionFeaturesTab.ts:1)
- Runtime status renderer: RuntimeStatusMarkdownRenderer (in same file)
- Registry: Extensions.ExtensionFeaturesRegistry (referenced from source)

Next action
- I will write the Remote Explorer, Breadcrumbs Picker, and Comments Tree Viewer feature docs in the same detailed format.
