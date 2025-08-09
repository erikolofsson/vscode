# Feature: Document Symbols / Outline

Summary
- Short name: Document Symbols / Outline
- Purpose: Provide an outline-of-symbols view (and breadcrumbs) for documents — shows symbols (classes, functions, variables, etc.), supports filtering, dragging symbols out to editors, icons, marker badges, and sorting (by name/type/position).

Representative source files
- Implementation and renderers: [`src/vs/workbench/contrib/codeEditor/browser/outline/documentSymbolsTree.ts`](src/vs/workbench/contrib/codeEditor/browser/outline/documentSymbolsTree.ts:1)
- Symbol model helpers: [`src/vs/editor/contrib/documentSymbols/browser/outlineModel.ts`](src/vs/editor/contrib/documentSymbols/browser/outlineModel.ts:1)
- Outline service / settings integration: [`src/vs/workbench/services/outline/browser/outline.ts`](src/vs/workbench/services/outline/browser/outline.ts:1)
- Icon & theming: [`src/vs/editor/contrib/symbolIcons/browser/symbolIcons.js`](src/vs/editor/contrib/symbolIcons/browser/symbolIcons.js:1)

Responsibilities
- Render grouped outline entries (OutlineGroup) and individual symbol items (OutlineElement / DocumentSymbol).
- Provide accessible navigation labels and ARIA support for the outline/breadcrumbs.
- Support drag-and-drop of symbols and produce appropriate drag payloads for editors and external drags.
- Provide per-symbol badges/decoration when markers are present (errors / warnings) and colorize accordingly.
- Respect user configuration flags to show/hide symbol kinds (`breadcrumbs.*` and `outline.*` config keys).

UI flows
- Outline tree and breadcrumbs consume the same symbol model (OutlineModel) and render either grouped or flat lists.
- Typing into outline find/filter highlights matches using createMatches() for label highlighting.
- Drag a symbol -> creates symbol-specific URI payload with selection (via withSelection())
- Clicking / opening a symbol reveals the symbol range in the editor (via opener APIs)

Data model & behavior
- Items: OutlineGroup (group of symbols) and OutlineElement (single symbol)
- Identity: stable id string on elements (used by identity provider)
- Filter: DocumentSymbolFilter consults resource-scoped configuration (`breadcrumbs.*` | `outline.*`) via ITextResourceConfigurationService
- Sorting: DocumentSymbolComparator implements compareByPosition / compareByType / compareByName using a numeric-aware collator

Runtime boundaries & services
- Renderer/UI layer uses:
  - ITextResourceConfigurationService for per-resource config
  - IThemeService for icon/theme colors
  - IConfigurationService for outline-specific configuration keys
  - Opener/list services for drag-and-drop and open-in-editor behavior
- Outline model and language document symbol providers are in the editor subsystem (language features)
- The component participates in the broader Outline service used by multiple panes (outline pane, breadcrumbs, quick pick)

Notable logic & details
- Symbol drag payload includes selection range encoded in the URI fragment (symbolRangeUri)
- Marker integration: decoration/badge rendering honors `problems.visibility`, `outline.problemsBadges`, and `outline.problemsColors` settings
- Deprecated symbols are rendered with strikethrough and de-emphasized matches
- The DocumentSymbolFilter maps SymbolKind to specific config keys via static map `kindToConfigName`

Tests & QA
- Tests should cover:
  - Visibility toggles per symbol kind and per-resource configuration
  - Drag payload correctness (URI plus selection fragment)
  - Marker/decoration rendering behavior across configuration permutations
  - Sorting modes and label highlighting behavior
- Integration:
  - Ensure outline updates when language providers change and when document symbols recompute

Porting notes — high level
- Symbol model & language providers:
  - Port must preserve ability to query document symbol providers for a document and produce the OutlineModel used by the UI
- Configuration hooks:
  - Recreate the per-resource configuration resolution semantics (ITextResourceConfigurationService)
- Drag-and-drop:
  - The port must serialize range selections into URIs (or equivalent) so editors opened from a drop will focus the intended symbol
- Theming:
  - Replicate symbol icon theming and badge color tokens for diagnostics

Per-feature porting checklist (see template)
- Required reads:
  - [`src/vs/workbench/contrib/codeEditor/browser/outline/documentSymbolsTree.ts`](src/vs/workbench/contrib/codeEditor/browser/outline/documentSymbolsTree.ts:1)
  - [`src/vs/editor/contrib/documentSymbols/browser/outlineModel.ts`](src/vs/editor/contrib/documentSymbols/browser/outlineModel.ts:1)
  - Configuration keys referenced via `OutlineConfigKeys` and `ITextResourceConfigurationService`
- Porting steps:
  1. Implement document-symbol aggregation API (OutlineModel) driven by language providers
  2. Implement virtualized outline tree with grouped and element renderers
  3. Implement drag payload generation for symbols (symbol range URI) and fill editors drag data
  4. Implement marker/diagnostic badge rendering and theming color tokens
  5. Add configuration mapping for kind-based visibility and sorting mode options
  6. Write unit and integration tests for symbol visibility, dragging, and marker UI

References
- Main renderer and drag/drop: [`src/vs/workbench/contrib/codeEditor/browser/outline/documentSymbolsTree.ts`](src/vs/workbench/contrib/codeEditor/browser/outline/documentSymbolsTree.ts:1)
