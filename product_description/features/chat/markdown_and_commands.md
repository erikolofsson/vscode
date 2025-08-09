# Chat — Markdown, Code Citation, Collapsible & Command Parts (batch)

Summary of batch read (files)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatCodeCitationContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatCodeCitationContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatCollapsibleContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatCollapsibleContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatCommandContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatCommandContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatAgentCommandContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAgentCommandContentPart.ts:1)

Responsibilities
- Markdown rendering and codeblock embedding; class: [`ChatMarkdownContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:66)
- Collapsed codeblock pill UI; class: [`CollapsedCodeBlock`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:377)
- Code citation export/editor flow; class: [`ChatCodeCitationContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatCodeCitationContentPart.ts:22)
- Generic collapsible container pattern; abstract class: [`ChatCollapsibleContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatCollapsibleContentPart.ts:19)
- Command button and agent command UI parts; [`ChatCommandButtonContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatCommandContentPart.ts:19) and [`ChatAgentCommandContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAgentCommandContentPart.ts:20)

Injected services & deps
- Markdown rendering, sanitizer and KaTeX: [`MarkdownRenderer`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:22) and [`MarkedKatexSupport`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:40)
- Editor/model services for codeblock models: [`ITextModelService` / `IModelService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:92)
- Label, editor, hover, menu, instantiation services for pills and toolbars (see [`CollapsedCodeBlock` constructor`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:393))
- Command execution and telemetry for command buttons and citations (`ICommandService`, `ITelemetryService`) referenced in [`chatCommandContentPart.ts:25`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatCommandContentPart.ts:25) and [`chatCodeCitationContentPart.ts:28`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatCodeCitationContentPart.ts:28)

UI flows & behavior
- Markdown render pipeline:
  - Render via `renderer.render(markdown.content, options)` with custom `codeBlockRendererSync` that creates codeblock editors or "pills" (see [`ChatMarkdownContentPart` render flow](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:126))
  - Codeblocks may be full editors (pooled via `EditorPool`) or collapsed pills referencing ephemeral codemapper URIs
- Collapsed codeblock pill:
  - Click or Enter opens diff/editor via `editorService.openEditor(...)` ([`CollapsedCodeBlock._showDiff()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:433))
  - Context menu obtains actions from `MenuId.ChatEditingCodeBlockContext` (see [`CollapsedCodeBlock` context menu](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:422))
- Command button:
  - Renders a Button and executes command via `commandService.executeCommand(...)` ([`ChatCommandButtonContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatCommandContentPart.ts:39))
- Agent command part:
  - Shows a subcommand label with hover and a rerun button, wired to a provided onClick callback ([`ChatAgentCommandContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAgentCommandContentPart.ts:24))

Patterns & lifecycle notes
- Codeblock rendering uses `CodeBlockModelCollection` to track per-session codeblock entries and vulnerabilities; updates are done via `update` / `updateSync` calls (see [`chatMarkdownContentPart.ts:160`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:160))
- Editor pooling reused via `EditorPool` / `ResourcePool<T>` pattern; callers must call `.reset()` on object before release (see `EditorPool.get()` at [`chatMarkdownContentPart.ts:356`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:356))
- Accessibility: aria labels, role=button, and SR alerts used elsewhere. Codeblock pills set `ariaLabel` summaries for screen readers ([`CollapsedCodeBlock.render()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:480))

Porting considerations & risks
- Markdown renderer sanitization and KaTeX: need safe HTML sanitizer and optional KaTeX rendering; allow-list of tags/attributes must be ported (`allowedChatMarkdownHtmlTags`) — reference in [`chatMarkdownContentPart.ts:51`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:51)
- Codeblock codemapper URIs and ephemeral model identities: platform must support ephemeral URI scheme and model lookup by URI; tests should stub `generateUuid()` for deterministic behavior
- Menu/context actions: dependency on `MenuId.ChatEditingCodeBlockContext` and `getFlatContextMenuActions` requires porting of menu APIs or shim
- Editor open flow & diff: `editorService.openEditor({ original, modified })` usage must be supported
- Telemetry and command execution: ensure telemetry APIs and command dispatch match expected semantics

Suggested tests
- Markdown → codeblock integration: render markdown with multiple codeblocks (complete/streaming) and assert correct widget types and EditorPool usage
- Collapsed pill behavior: clicking pill opens expected editor/diff; context menu actions resolve properly
- Command button execution: assert `commandService.executeCommand` called with expected args and disabled state for restored chats
- Agent command rerun: ensure onClick callback invoked and hover content shown

Next automated actions
1. Write this synthesized note into the feature docset (this file).
2. Mark this batch completed in the TODO and continue with next files (5-file batch).

Notes for the next worker
- Preserve exact codeblock-indexing and ownerMarkdownPartId semantics (used to match codeblock entries across streaming renders)
- When writing tests, stub `textModelService.createModelReference` and `generateUuid()` to avoid flakiness.

End of file.
