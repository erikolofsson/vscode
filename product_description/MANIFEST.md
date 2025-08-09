# Product manifest — Code - OSS

This repository of documents is the master manifest for the feature-level product documentation generated from the source tree. The goal is to enumerate every feature, group features into themes, and produce per-feature documentation sufficient to plan and implement a full rewrite in another language.

Primary documents
- Overview: [`product_description/OVERVIEW.md`](product_description/OVERVIEW.md:1)
- Porting checklist template: [`product_description/PORTING_CHECKLIST.md`](product_description/PORTING_CHECKLIST.md:1)

How this manifest is organized
- Themes (high-level categories) live under: [`product_description/themes/`](product_description/themes/:1)
- Feature docs are grouped inside theme folders; each feature is a single .md file
- A per-feature TODO list will be created alongside each feature doc

Top-level theme index (first pass)
- User interface and UX
  - Theme file: [`product_description/themes/ui.md`](product_description/themes/ui.md:1)
- Core editor features
  - Theme file: [`product_description/themes/editor.md`](product_description/themes/editor.md:1)
- Workbench (views, panels, layout, window management)
  - Theme file: [`product_description/themes/workbench.md`](product_description/themes/workbench.md:1)
- Extensions and extension host
  - Theme file: [`product_description/themes/extensions.md`](product_description/themes/extensions.md:1)
- CLI, packaging, and scripts
  - Theme file: [`product_description/themes/cli.md`](product_description/themes/cli.md:1)
- Language features and language servers
  - Theme file: [`product_description/themes/language-features.md`](product_description/themes/language-features.md:1)
- Debugging, profiling, runtimes
  - Theme file: [`product_description/themes/debugging.md`](product_description/themes/debugging.md:1)
- Filesystem, workspace, remote, and storage
  - Theme file: [`product_description/themes/files-and-remote.md`](product_description/themes/files-and-remote.md:1)
  - Features:
    - Files / Explorer & file actions
      - Feature doc: [`product_description/features/files/explorer_and_file_actions.md`](product_description/features/files/explorer_and_file_actions.md:1)
      - Feature doc: [`product_description/features/files/views_and_viewer.md`](product_description/features/files/views_and_viewer.md:1)
      - Feature doc: [`product_description/features/files/editors.md`](product_description/features/files/editors.md:1)
      - Feature doc: [`product_description/features/files/import_and_export.md`](product_description/features/files/import_and_export.md:1)
      - Feature doc: [`product_description/features/files/service_and_commands.md`](product_description/features/files/service_and_commands.md:1)
      - Feature doc: [`product_description/features/files/contributions_and_viewlet.md`](product_description/features/files/contributions_and_viewlet.md:1)
      - Feature doc: [`product_description/features/files/drag_and_drop_and_import_export.md`](product_description/features/files/drag_and_drop_and_import_export.md:1)
      - Feature doc: [`product_description/features/files/editors_deep_dive.md`](product_description/features/files/editors_deep_dive.md:1)
      - Feature doc: [`product_description/features/files/adapters.md`](product_description/features/files/adapters.md:1)
      - Feature doc: [`product_description/features/files/adapters_tests.md`](product_description/features/files/adapters_tests.md:1)
  - Status: Files docset drafted; QA pass completed and docset is ready for implementation handoff.
- Tests and CI
  - Theme file: [`product_description/themes/tests.md`](product_description/themes/tests.md:1)
- Platform & runtime subsystems (main process, renderer, extension host, shared services)
  - Theme file: [`product_description/themes/runtime.md`](product_description/themes/runtime.md:1)

Example feature placeholders (initial seeds)
- Editor / Marker navigation widget
  - Feature doc: [`product_description/features/editor/marker_navigation.md`](product_description/features/editor/marker_navigation.md:1)
  - Source examples discovered: [`src/vs/editor/contrib/gotoError/browser/gotoErrorWidget.ts`](src/vs/editor/contrib/gotoError/browser/gotoErrorWidget.ts:1)
- Workbench / Open Editors view
  - Feature doc: [`product_description/features/workbench/open_editors.md`](product_description/features/workbench/open_editors.md:1)
  - Source examples discovered: [`src/vs/workbench/contrib/files/browser/views/openEditorsView.ts`](src/vs/workbench/contrib/files/browser/views/openEditorsView.ts:1)
- Chat / Conversation UI
  - Feature docs (first-pass, expanded):
    - [`product_description/features/chat/accessibility_and_a11y.md`](product_description/features/chat/accessibility_and_a11y.md:1)
    - [`product_description/features/chat/accessibility.md`](product_description/features/chat/accessibility.md:1)
    - [`product_description/features/chat/agent_changes_collections_anchors.md`](product_description/features/chat/agent_changes_collections_anchors.md:1)
    - [`product_description/features/chat/agent_changes_confirmation_collapsible_references.md`](product_description/features/chat/agent_changes_confirmation_collapsible_references.md:1)
    - [`product_description/features/chat/agents_and_prompts.md`](product_description/features/chat/agents_and_prompts.md:1)
    - [`product_description/features/chat/attachment_model_sessions_setup.md`](product_description/features/chat/attachment_model_sessions_setup.md:1)
    - [`product_description/features/chat/attachments_and_markdown.md`](product_description/features/chat/attachments_and_markdown.md:1)
    - [`product_description/features/chat/attachments_and_tools.md`](product_description/features/chat/attachments_and_tools.md:1)
    - [`product_description/features/chat/attachments_markdown_textedit_multidiff_progress.md`](product_description/features/chat/attachments_markdown_textedit_multidiff_progress.md:1)
    - [`product_description/features/chat/attachments_markdown_textedit_toolio.md`](product_description/features/chat/attachments_markdown_textedit_toolio.md:1)
    - [`product_description/features/chat/attachments_tool_io_command_collapsible_elicitation.md`](product_description/features/chat/attachments_tool_io_command_collapsible_elicitation.md:1)
    - [`product_description/features/chat/attachments_widget_and_editor.md`](product_description/features/chat/attachments_widget_and_editor.md:1)
    - [`product_description/features/chat/codeblocks.md`](product_description/features/chat/codeblocks.md:1)
    - [`product_description/features/chat/collapsible_collections_commands_confirmation.md`](product_description/features/chat/collapsible_collections_commands_confirmation.md:1)
    - [`product_description/features/chat/collapsible_commands_agent_changes.md`](product_description/features/chat/collapsible_commands_agent_changes.md:1)
    - [`product_description/features/chat/collections_textedit_attachments_and_progress.md`](product_description/features/chat/collections_textedit_attachments_and_progress.md:1)
    - [`product_description/features/chat/confirmation_error_elicitation.md`](product_description/features/chat/confirmation_error_elicitation.md:1)
    - [`product_description/features/chat/confirmation_error_extensions_contentparts.md`](product_description/features/chat/confirmation_error_extensions_contentparts.md:1)
    - [`product_description/features/chat/content_parts_misc.md`](product_description/features/chat/content_parts_misc.md:1)
    - [`product_description/features/chat/drag_and_drop_attachments_contextpicker_followups_options.md`](product_description/features/chat/drag_and_drop_attachments_contextpicker_followups_options.md:1)
    - [`product_description/features/chat/editor_integration.md`](product_description/features/chat/editor_integration.md:1)
    - [`product_description/features/chat/elicitation_error_and_confirmations.md`](product_description/features/chat/elicitation_error_and_confirmations.md:1)
    - [`product_description/features/chat/elicitation_error_markdown_multidiff.md`](product_description/features/chat/elicitation_error_markdown_multidiff.md:1)
    - [`product_description/features/chat/extensions_pullrequests_anchors_tasks_quota.md`](product_description/features/chat/extensions_pullrequests_anchors_tasks_quota.md:1)
    - [`product_description/features/chat/image_and_content_parts.md`](product_description/features/chat/image_and_content_parts.md:1)
    - [`product_description/features/chat/input.md`](product_description/features/chat/input.md:1)
    - [`product_description/features/chat/markdown_and_commands.md`](product_description/features/chat/markdown_and_commands.md:1)
    - [`product_description/features/chat/markdown_and_io.md`](product_description/features/chat/markdown_and_io.md:1)
    - [`product_description/features/chat/markdown_textedit_progress_and_attachments.md`](product_description/features/chat/markdown_textedit_progress_and_attachments.md:1)
    - [`product_description/features/chat/markdown_textedit_progress_references.md`](product_description/features/chat/markdown_textedit_progress_references.md:1)
    - [`product_description/features/chat/options.md`](product_description/features/chat/options.md:1)
    - [`product_description/features/chat/output_and_sessions.md`](product_description/features/chat/output_and_sessions.md:1)
    - [`product_description/features/chat/overview.md`](product_description/features/chat/overview.md:1)
    - [`product_description/features/chat/progress_todo_toolio_trees_attachments.md`](product_description/features/chat/progress_todo_toolio_trees_attachments.md:1)
    - [`product_description/features/chat/pull_quota_task_todo_tree.md`](product_description/features/chat/pull_quota_task_todo_tree.md:1)
    - [`product_description/features/chat/pullreq_task_todo_and_toolio.md`](product_description/features/chat/pullreq_task_todo_and_toolio.md:1)
    - [`product_description/features/chat/quick_paste_markdown_output.md`](product_description/features/chat/quick_paste_markdown_output.md:1)
    - [`product_description/features/chat/references_and_actions.md`](product_description/features/chat/references_and_actions.md:1)
    - [`product_description/features/chat/references_and_trees.md`](product_description/features/chat/references_and_trees.md:1)
    - [`product_description/features/chat/references_trees_and_context_actions.md`](product_description/features/chat/references_trees_and_context_actions.md:1)
    - [`product_description/features/chat/references_trees_collections_toolio.md`](product_description/features/chat/references_trees_collections_toolio.md:1)
    - [`product_description/features/chat/rendering.md`](product_description/features/chat/rendering.md:1)
    - [`product_description/features/chat/service_and_model.md`](product_description/features/chat/service_and_model.md:1)
    - [`product_description/features/chat/setup_and_contribs.md`](product_description/features/chat/setup_and_contribs.md:1)
    - [`product_description/features/chat/testing.md`](product_description/features/chat/testing.md:1)
    - [`product_description/features/chat/tests_and_porting_checklist.md`](product_description/features/chat/tests_and_porting_checklist.md:1)
    - [`product_description/features/chat/textedit_diff.md`](product_description/features/chat/textedit_diff.md:1)
    - [`product_description/features/chat/tool_invocation_confirm_terminal.md`](product_description/features/chat/tool_invocation_confirm_terminal.md:1)
    - [`product_description/features/chat/tool_invocation_output_progress.md`](product_description/features/chat/tool_invocation_output_progress.md:1)
    - [`product_description/features/chat/tool_invocation_parts.md`](product_description/features/chat/tool_invocation_parts.md:1)
    - [`product_description/features/chat/tool_invocation_subparts.md`](product_description/features/chat/tool_invocation_subparts.md:1)
    - [`product_description/features/chat/tool_invocation.md`](product_description/features/chat/tool_invocation.md:1)
    - [`product_description/features/chat/toolinvocation_confirmation_invocation_output_progress.md`](product_description/features/chat/toolinvocation_confirmation_invocation_output_progress.md:1)
    - [`product_description/features/chat/toolinvocation_terminal_extensions_results.md`](product_description/features/chat/toolinvocation_terminal_extensions_results.md:1)
    - [`product_description/features/chat/widget_and_input.md`](product_description/features/chat/widget_and_input.md:1)
    - [`product_description/features/chat/widget_input_list_renderer_editor_viewpane.md`](product_description/features/chat/widget_input_list_renderer_editor_viewpane.md:1)
    - [`product_description/features/chat/widget.md`](product_description/features/chat/widget.md:1)
    - [`product_description/features/chat/title_and_misc_actions.md:1`](product_description/features/chat/title_and_misc_actions.md:1)
    - [`product_description/features/chat/onboarding_import_export_models_quickinput.md:1`](product_description/features/chat/onboarding_import_export_models_quickinput.md:1)
    - [`product_description/features/chat/transfer_codeblocks_toolpicker.md:1`](product_description/features/chat/transfer_codeblocks_toolpicker.md:1)
    - [`product_description/features/chat/accessibility_and_clear_codeblock_actions.md:1`](product_description/features/chat/accessibility_and_clear_codeblock_actions.md:1)
  - Source examples discovered: [`src/vs/workbench/contrib/chat/browser/chatWidget.ts`](src/vs/workbench/contrib/chat/browser/chatWidget.ts:1), [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1)

Next steps (short term)
1. Create the top-level docs and theme files (under [`product_description/`](product_description/:1) and [`product_description/themes/`](product_description/themes/:1)).
2. Iteratively scan the repository in small batches (5 files at a time), extract features and their related source files, and author the per-feature markdown files under [`product_description/features/`](product_description/features/:1).
3. For each feature, produce a per-feature TODO (file-level reads, call graph, dataflow, tests, porting notes) and link it from the feature doc.
4. Update this manifest as features are discovered and documented.

How to read this manifest
- Each link in this manifest points to the generated .md file path followed by a line anchor (line 1). Those .md files will contain:
  - Feature name and summary
  - Motivation and responsibilities
  - Related source files (file paths with code excerpts)
  - Public APIs and extension points
  - UI flows and screenshots (if available)
  - Data model and persistence details
  - Tests mapping
  - Porting checklist and estimated effort

If you want me to start immediately, I will proceed automatically (per your earlier instruction). I will:
- create the initial directory structure under [`product_description/`](product_description/:1)
- create the seed files referenced above
- begin the iterative scan (5-file reads) and populate feature docs for discovered features

I will continue without asking for further confirmation and will update this manifest and the product_description/ tree as I make progress.
