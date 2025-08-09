Chat: Elicitation, Error UI, Markdown Rendering & Multi-Diff

Summary
This document summarizes responsibilities, UI flows, lifecycle patterns, injected services and porting considerations for elicitation requests, error UI, markdown rendering (including codeblocks & KaTeX) and multi-diff summaries.

Key files
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatElicitationContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatElicitationContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorConfirmationPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatErrorConfirmationPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1)

Responsibilities
- Elicitation: render a confirmation widget (accept/reject) wired to the elicitation API, update UI on hide, and provide accessible labeling and focus.
- Error content: render error/warning/info notifications with rendered markdown and appropriate iconography.
- Error confirmation: render error details with action buttons that construct IChatSendRequestOptions and call chatService.sendRequest; fire height changes when UI updates.
- Markdown content: full markdown rendering pipeline with sanitizer options, async KaTeX support, codeblock rendering that creates either pooled editors (EditorPool / ResourcePool) or collapsed "pills", decorations, and layout resizing participants.
- MultiDiff: show a summary header, collapsed/expanded list of changed files, open multi-diff editor or per-file diffs, and provide accessibility labels.

Injected services & runtime dependencies
- IInstantiationService for creating widgets and content parts (ChatConfirmationWidget, ChatMarkdownDecorationsRenderer, ResourceLabels, MultiDiffEditorInput).
- IChatService, IChatWidgetService, and IChatAccessibilityService for request flows and accessibility signaling.
- Editor/model services: IEditorService, IEditorGroupsService, IModelService, ITextModelService for opening editors, transient models, and diffs.
- Markdown and KaTeX: MarkdownRenderer and MarkedKatexSupport (async load and sanitizer options).
- Lists & menus: WorkbenchList, MenuService, ContextMenuService, ResourceLabels for file listing and context menus.
- Reactive primitives: autorun, observable/observableValue and ResizeObserver patterns used across parts.

UI flows
- Elicitation: create ChatConfirmationWidget with accept/reject buttons; on click call elicitation.accept()/reject(), hide buttons, update rendered message (codeblock appended when acceptedResult exists), fire onDidChangeHeight, and call chatAccessibilityService.acceptElicitation for screen-reader notification.
- Error rendering: instantiate ChatErrorWidget with level-specific icon and attach rendered markdown content; widget is focusable (tabIndex) and displays appropriate icon classes.
- Error confirmation: build options including agentId, slashCommand, confirmation label, userSelectedModelId and merge widget.getModeRequestOptions(); call chatService.sendRequest(sessionId, prompt, options); on success fire height change.
- Markdown rendering: renderer.render(markdown.content, { sanitizerConfig, codeBlockRendererSync, asyncRenderCallback, markedExtensions }) → codeBlockRendererSync handles:
  - 'vscode-extensions' pseudo-language producing ChatExtensionsContentPart,
  - local-file codeblocks parsed into textModel references,
  - normal codeblocks either rendered with EditorPool.get() or rendered as CollapsedCodeBlock pills depending on streaming and completeness.
  - register ref.object.onDidChangeContentHeight to forward height changes.
- MultiDiff: header includes toggle chevron, 'view all' opens MultiDiffEditorInput, list shows limited items (MAX_ITEMS_SHOWN) with fixed row height, clicking opens diff or single file in editor.

Lifecycle patterns & contracts
- ChatConfirmationWidget: provide setShowButtons and onDidChangeHeight; callers wire that to parent onDidChangeHeight and hide buttons when confirmation is used.
- EditorPool / ResourcePool: ResourcePool.get() returns pooled items; EditorPool.get() wraps with IDisposableReference that includes isStale and dispose semantics (reset on dispose, mark stale, and release back to pool).
- CodeBlockModelCollection: updateSync for fast updates during streaming, and async update for codemapperUri population; ephemeral URIs and transient models are used frequently.
- KaTeX & resize: MarkedKatexSupport is loaded asynchronously (if needed) and a ResizeObserver is used to notify math layout participants and to wrap KaTeX blocks in horizontally scrollable DomScrollableElement.
- MultiDiff list: list.layout(height) & container.style.height are set after populating items; identityProvider uses URI.toString().

Porting considerations & high-risk areas
- Markdown renderer & sanitizer: exact sanitizer options (allowedChatMarkdownHtmlTags and allowedMarkdownHtmlAttributes) and MarkedKatexSupport behavior must be preserved to avoid XSS and layout regressions.
- Streaming codeblock behavior: the distinction between pills and editor-backed codeblocks depends on isCodeBlockComplete detection and codeBlockModelCollection semantics—this is high risk to port incorrectly.
- Editor pooling/disposal semantics: ResourcePool/_register ownership and EditorPool isStale/reset semantics must be replicated to avoid reuse-after-dispose and memory leaks.
- Transient model creation: host must implement equivalent to ITextModelService.createModelReference for ephemeral models used when rendering codeblocks or creating diff models.
- Multi-diff editor: MultiDiffEditorInput and MultiDiffEditorItem are relied upon; if host lacks multi-diff support an adapter or alternate UX must be provided.
- Accessibility: ensure tabIndex, ariaLabel, keyboard handlers (Enter/Space) and chatAccessibilityService mappings are preserved.

Test ideas and verification
- Unit: ChatElicitationContentPart — clicking accept/reject calls elicitation.accept()/reject(); confirmationWidget.setShowButtons(false) called and accessibility service invoked.
- Unit: ChatErrorWidget — correct Codicon/iconClass mapping for Warning/Error/Info and renderer.render called with provided content.
- Integration: Streaming markdown codeblock flow — simulate partial codeblock streaming; verify pill renders then replaced/updated when codemapperUri appears; onDidChangeHeight fires.
- Integration: EditorPool reuse test — get(), render, dispose(), get() again → ensure reset called and isStale behavior observed; pool.inUse tracking updated.
- Integration/UI: MultiDiff list opens appropriate editor inputs for diff vs single-file items; view-all opens MultiDiffEditorInput in active group.

Verbatim patterns to preserve
- EditorPool get/dispose wrapper:
  const ref = this.editorPool.get();
  let stale = false;
  return {
    object: codeBlock,
    isStale: () => stale,
    dispose: () => {
      codeBlock.reset();
      stale = true;
      this._pool.release(codeBlock);
    }
  };
- codeblockHasClosingBackticks helper:
  return !!str.match(/\n```+$/);
- KaTeX load + ResizeObserver:
  MarkedKatexSupport.loadExtension(...).then(() => doRenderMarkdown());
  const observer = new ResizeObserver(() => this.mathLayoutParticipants.forEach(layout => layout()));

Accessibility notes
- Preserve tabIndex and ariaLabel usage (Elicitation.domNode.tabIndex = 0 and ariaLabel composition; CollapsedCodeBlock keyboard handlers for Enter/Space).
- Ensure hover/persistent tooltip behavior for codeblock pills and list items via hoverService equivalents.

Next steps
- Add this doc to the MANIFEST and continue with the next prioritized batch of five files.
- Prioritize remaining chatContentParts under toolInvocationParts/ and media/ if present.
