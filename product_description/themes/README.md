# Product themes — Code - OSS

This folder contains the theme-level indexes that group features into high-level themes. Each theme file references individual feature documents in a tree structure.

Themes (first pass)
- User interface and UX
  - Overview: [`product_description/themes/ui.md`](product_description/themes/ui.md:1)
  - Features:
    - Open Editors (workbench) — [`product_description/features/workbench/open_editors.md`](product_description/features/workbench/open_editors.md:1)
    - Breadcrumbs Picker (editor) — [`product_description/features/editor/breadcrumbs_picker.md`](product_description/features/editor/breadcrumbs_picker.md:1)
- Core editor features
  - Overview: [`product_description/themes/editor.md`](product_description/themes/editor.md:1)
  - Features:
    - Marker navigation / goto error — [`product_description/features/editor/marker_navigation.md`](product_description/features/editor/marker_navigation.md:1) (seeded from [`src/vs/editor/contrib/gotoError/browser/gotoErrorWidget.ts`](src/vs/editor/contrib/gotoError/browser/gotoErrorWidget.ts:1))
- Workbench (views, panels, layout, window management)
  - Overview: [`product_description/themes/workbench.md`](product_description/themes/workbench.md:1)
  - Features:
    - Open Editors view — [`product_description/features/workbench/open_editors.md`](product_description/features/workbench/open_editors.md:1)
    - Loaded Scripts view (debug) — [`product_description/features/debug/loaded_scripts.md`](product_description/features/debug/loaded_scripts.md:1)
- Extensions & extension host
  - Overview: [`product_description/themes/extensions.md`](product_description/themes/extensions.md:1)
  - Features:
    - Extension Features Tab — [`product_description/features/extensions/extension_features_tab.md`](product_description/features/extensions/extension_features_tab.md:1)
- Debugging, profiling, runtimes
  - Overview: [`product_description/themes/debugging.md`](product_description/themes/debugging.md:1)
  - Features:
    - Debug Console / REPL — [`product_description/features/debug/repl.md`](product_description/features/debug/repl.md:1)
    - Loaded Scripts — [`product_description/features/debug/loaded_scripts.md`](product_description/features/debug/loaded_scripts.md:1)
- Filesystem, workspace, remote
  - Overview: [`product_description/themes/files-and-remote.md`](product_description/themes/files-and-remote.md:1)
  - Features:
    - Remote Explorer & Help — [`product_description/features/remote/remote_explorer.md`](product_description/features/remote/remote_explorer.md:1)
- Notebooks
  - Overview: [`product_description/themes/notebooks.md`](product_description/themes/notebooks.md:1)
  - Features:
    - Notebook Outline — [`product_description/features/notebook/notebook_outline.md`](product_description/features/notebook/notebook_outline.md:1)
    - Notebook Variables — [`product_description/features/notebook/notebook_variables.md`](product_description/features/notebook/notebook_variables.md:1)
- Processes & diagnostics
  - Overview: [`product_description/themes/process.md`](product_description/themes/process.md:1)
  - Features:
    - Process Explorer — [`product_description/features/process/process_explorer.md`](product_description/features/process/process_explorer.md:1)
- Collaboration, code review & comments
  - Overview: [`product_description/themes/comments.md`](product_description/themes/comments.md:1)
  - Features:
    - Comments Tree Viewer — [`product_description/features/comments/comments_tree.md`](product_description/features/comments/comments_tree.md:1)
- Tools, CLI, packaging, scripts
  - Overview: [`product_description/themes/cli.md`](product_description/themes/cli.md:1)
- Tests and CI
  - Overview: [`product_description/themes/tests.md`](product_description/themes/tests.md:1)
- Runtime & platform subsystems
  - Overview: [`product_description/themes/runtime.md`](product_description/themes/runtime.md:1)

Notes
- The above is an initial mapping based on the files scanned so far. I will create each overview theme file (e.g., `product_description/themes/ui.md`) next and progressively populate them with more features as I continue scanning the repository in batches of 5 files.
- Each feature file includes a per-feature porting checklist and a list of source files to read next. Where necessary I will add finer-grained feature files (e.g., sub-features) and link them in the appropriate theme file.
