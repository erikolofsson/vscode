# Chat — Testing

Scope
- This document lists recommended unit, integration, accessibility, visual-regression and performance tests for the Chat subsystem to ensure behavior parity when porting or refactoring.

Test categories and targets

1) Unit tests
- Aim: validate pure logic, small component behavior, and event emitters in isolation.
- Targets:
  - ChatAttachmentModel: add/delete/update events, omitted-state handling, asImageVariableEntry resolution logic. See implementation: [`src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1)
  - Markdown rendering wrapper: sanitizer options and openMarkdownLink behavior. See: [`src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1)
  - Prompt parser / IPromptsService: template expansion, variable resolution, error conditions (prompt file locations referenced in prompts code).
  - Model/agent selection logic: ILanguageModelsService-backed code that persists last-used model and handles capability flags.
  - Content part equality/diff functions (parts' hasSameContent) used by the renderer diff algorithm.

2) Renderer / DOM unit-ish tests
- Aim: verify individual content parts render expected DOM structure and produce expected accessibility labels.
- Targets:
  - ChatListItemRenderer behavior for static responses and progressive rendering decisions: uses diffing/path to choose parts. See: [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1)
  - Individual content parts: ChatMarkdownContentPart, ChatTextEditContentPart, ChatToolInvocationPart, ChatUsedReferencesListContentPart — validate generated DOM, aria attributes, and event wiring.
  - Attachment widgets: FileAttachmentWidget, ImageAttachmentWidget and others for markup and hover content. See: [`src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1)

3) Integration tests
- Aim: exercise flows across components and services.
- Key flows:
  - Compose → Send → Progressive stream → Finalize:
    - Simulate chatService.sendRequest returning a progressive stream of response chunks, assert partial DOM updates, streaming indicators, and final state.
    - Validate render-rate smoothing and final content equality.
  - Attachments in request:
    - Add file/image/prompt attachments via ChatAttachmentModel; assert attachments are included in outgoing request payloads and that omitted/partial states are respected.
  - Editor integration: code block expands to embedded editor and "Open in Editor" action opens an editor with correct selection/URI. See: [`src/vs/workbench/contrib/chat/browser/chatEditor.ts:1`](src/vs/workbench/contrib/chat/browser/chatEditor.ts:1)
  - Checkpoints & text-edit application:
    - When a response produces textEditGroup parts, validate preview in diff editor, and applying edits updates workspace files as expected.

4) Accessibility tests
- Aim: ensure screen-reader semantics and keyboard navigation.
- Tests:
  - Verify presence and behavior of aria-live regions for progressive updates and final completion announcements.
  - Keyboard navigation: focus movement through list items, attachments, toolbars, and embedded editors.
  - Verify aria-labels on attachments and code blocks, and that hover/tooltips have accessible fallbacks.
- Reference code: [`src/vs/workbench/contrib/chat/browser/chatAccessibilityProvider.ts:1`] and [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1)

5) Visual regression / snapshot tests
- Aim: detect unintended visual/structural changes.
- Targets:
  - Full list render with a representative complex response containing:
    - references, code blocks, tool invocation parts, progress messages, and attachments.
  - Input area with multiple attachments and toolbar states.
- Strategy:
  - Produce deterministic fixtures (mock ChatViewModel instances) and capture DOM snapshots. Use diff thresholds for images and element tree diffs for structural regressions.

6) Performance tests
- Aim: measure memory, CPU, and responsiveness under realistic loads.
- Targets:
  - Rendering throughput and memory when dozens/hundreds of responses contain code blocks (ensuring EditorPool reuse works).
  - Progressive render timer behavior and UI responsiveness during heavy streaming.
- Metrics:
  - Time-to-first-render for progressive chunk.
  - Memory use per active editor instance.
  - Time to apply a text-edit group to the workspace.

7) End-to-end smoke tests
- Aim: validate overall system in a real runtime (packaged or dev web).
- Tests:
  - Create a session, send a request with attachments, open code block in editor, apply suggested edits, and verify workspace changes.
  - Sign-in / entitlement gated scenarios for agent features if relevant.

Test harness and mocks
- Mock IChatService to simulate server-side progressive streams, cancellations and tool invocation results.
- Mock ILanguageModelsService and ILanguageModelToolsService for deterministic model/tool metadata.
- Use in-memory file system or a test workspace for file/attachment behaviors (IFileService mock).
- Provide deterministic timers or freeze time during progressive rendering tests to eliminate flakiness.

Test data and fixtures
- Create fixtures for:
  - Progressive response stream (chunked Markdown content with code blocks).
  - Attachment sets (file URIs, image buffers, prompt file references).
  - Tool invocation payloads and output shapes for tool parts.
  - Prompt files with nested references and error scenarios.

Coverage and prioritization
- Priority 1 (must-have): unit tests for attachment model, markdown renderer, list renderer diff logic; basic integration progress stream test.
- Priority 2: editor integration tests and attachment drag/open behavior.
- Priority 3: visual regression and performance benchmarks.

Cross-links
- Implementation references:
  - Renderer & list: [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1)
  - Input & attachments: [`src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1), [`src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1)
  - Editor integration: [`src/vs/workbench/contrib/chat/browser/chatEditor.ts:1`](src/vs/workbench/contrib/chat/browser/chatEditor.ts:1)
