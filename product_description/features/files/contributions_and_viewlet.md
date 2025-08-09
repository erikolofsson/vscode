# Files: Contributions & Viewlet

Summary:

This document synthesizes responsibilities and porting notes for contribution and viewlet wiring of the Files feature:
- [`src/vs/workbench/contrib/files/browser/explorerFileContrib.ts:1`](src/vs/workbench/contrib/files/browser/explorerFileContrib.ts:1)
- [`src/vs/workbench/contrib/files/browser/explorerViewlet.ts:1`](src/vs/workbench/contrib/files/browser/explorerViewlet.ts:1)
- [`src/vs/workbench/contrib/files/browser/fileActions.contribution.ts:1`](src/vs/workbench/contrib/files/browser/fileActions.contribution.ts:1)
- [`src/vs/workbench/contrib/files/browser/files.contribution.ts:1`](src/vs/workbench/contrib/files/browser/files.contribution.ts:1)

Responsibilities

- ExplorerFileContrib: lightweight registry for file rendering contributions. Implements descriptor pattern; contributors create instances per explorer template. See [`explorerFileContrib.ts:39`](src/vs/workbench/contrib/files/browser/explorerFileContrib.ts:39).

- ExplorerViewlet: view container and view registration. Registers the Explorer and Open Editors views, welcome content, icons, and view-pane container class. See [`explorerViewlet.ts:45`](src/vs/workbench/contrib/files/browser/explorerViewlet.ts:45).

- fileActions.contribution: commands, keybindings, menus, and command palette registrations for file operations and open-editors menus. See [`fileActions.contribution.ts:31`](src/vs/workbench/contrib/files/browser/fileActions.contribution.ts:31).

- files.contribution: workbench registrations: singleton services, editor panes, editor factories/serializers, workspace watcher registration, configuration schema for files and explorer. See [`files.contribution.ts:58`](src/vs/workbench/contrib/files/browser/files.contribution.ts:58).

Key patterns & wiring

- Registries and descriptors: uses Registry (Views, ViewContainers, EditorPane, EditorFactory) and SyncDescriptor/SyncDescriptor.Create to lazily instantiate view/editor classes. The view container is registered via Registry.as(...). See view container creation [`explorerViewlet.ts:257`](src/vs/workbench/contrib/files/browser/explorerViewlet.ts:257).

- Workbench contributions & phases: contributions are registered with registerWorkbenchContribution2 and can be scheduled at different WorkbenchPhase values (BlockStartup, AfterRestored, etc.). Important for ordering initialization (e.g., TextFileEditorTracker and WorkspaceWatcher). See [`files.contribution.ts:102`](src/vs/workbench/contrib/files/browser/files.contribution.ts:102).

- Menu & command registrations: fileActions.contribution wires MenuRegistry and KeybindingsRegistry heavily to expose contextual commands (ExplorerContext, OpenEditorsContext, EditorTitleContext, Menubar). Command handlers often delegate to functions in [`fileActions.ts:1`](src/vs/workbench/contrib/files/browser/fileActions.ts:1) and [`fileCommands.ts:1`](src/vs/workbench/contrib/files/browser/fileCommands.ts:1).

- Welcome content & view toggling: viewsRegistry.registerViewWelcomeContent is used to show context-aware markdown with command links in empty/explorer states. See examples in [`explorerViewlet.ts:286`](src/vs/workbench/contrib/files/browser/explorerViewlet.ts:286).

Notable implementation details to preserve when porting

- Descriptor-based instantiation: IExplorerFileContributionDescriptor.create(insta, container) → new instance per template. Port must provide equivalent factory/DI pattern so extension-style contributions can attach to explorer rows.

- Viewlet structure: ExplorerViewPaneContainer extends ViewPaneContainer and customizes createView to inject a delegate affecting open-editors refresh delay. Preserve delegate hooks and focus behavior.

- Configuration schema: files.contribution registers a large configuration schema (files.* and explorer.*). Port should replicate schema and validation where possible or provide mapping.

- Workbench phases ordering: TextFileEditorTracker, TextFileSaveErrorHandler, WorkspaceWatcher, DirtyFilesIndicator — ordering matters for restore and watcher initialization.

Porting risks & mitigations

- Registry surface area: The host must provide equivalents for Registry, MenuRegistry, ViewsRegistry, and Editor registries. If not available, implement a shim that supports registration and lazy instantiation or adapt to the host's plugin/contribution system.

- Menu/ContextKey system: fileActions.contribution depends on ContextKeyExpr conditions and many context keys. Port requires either implementing a ContextKey engine or collapsing visibility logic into runtime predicates for menus/actions.

- i18n & telemetry: code uses localized strings (nls/localize) and telemetry hooks (mark, telemetry service). Keep localization hooks or extract static English strings if localization is out of scope.

- Workbench lifecycle: WorkbenchPhase-driven contributions assume a lifecycle. Port must provide equivalent sequencing or initialize critical components explicitly in the correct order to avoid races.

- Native vs Web feature flags: code uses isWeb/isNative/isWindows to register different defaults and enable/disable features (hotExit, file system access). Ensure platform detection is reproduced and features gated accordingly.

Minimal adapter list suggested

- ViewRegistryAdapter: supports registering view containers, view descriptors, and welcome content with conditionals.
- MenuAdapter: supports MenuId groups, conditional when expressions, and keybinding registration.
- ContributionScheduler: allow registering workbench contributions with phases to ensure correct startup ordering.
- DescriptorFactory: to support SyncDescriptor and creation of editor/view instances via DI/instantiation service.

Testing suggestions

- Verify viewlet open/close and welcome content conditions across workspace states (empty, single-folder, multi-root, remote).
- Validate menu visibility for ExplorerContext and OpenEditorsContext with different context key scenarios (readonly folders, dirty editors, multi-select).
- Confirm editor registrations (TextFileEditor, BinaryFileEditor) open correctly via EditorFactory and serializers.

Actionable next steps

1. Create a feature doc: Drag & Drop / Import & Export deep dive from [`fileImportExport.ts:1`](src/vs/workbench/contrib/files/browser/fileImportExport.ts:1).
2. Finalize two remaining top-level reads: explore any files in `editors/` not yet synthesized and run QA pass across files feature docs.
3. Update product_description/MANIFEST.md to include this new document and cross-link from other files docs.

Owner: Kilo Code

End.
