# Chat — Widget

Purpose
- Hosts the chat conversation UI: list of messages, input area, and toolbars. Coordinates send/resend, editing, and session lifecycle.

Responsibilities
- Compose and layout message list and input; instantiate ChatList and ChatInput parts.
- Coordinate session-level operations: open/close sessions, restore mementos, focus management.
- Coordinate sending requests to ChatService and handle responses, progressive rendering and cancellation.
- Register widget with IChatWidgetService and expose focus/selection events.

Key implementation files
- [`src/vs/workbench/contrib/chat/browser/chatWidget.ts:1`] — primary composition and logic for the widget.
- [`src/vs/workbench/contrib/chat/browser/chatViewPane.ts:1`] — ViewPane lifecycle and memento wiring for panel/editor locations.
- [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1`] — list renderer for requests/responses and progressive render logic.
- [`src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1`] — input editor, attachments and toolbars.
- [`src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1`] — attachment lifecycle referenced by the widget.

Public APIs & Services
- Interacts with IChatService to send requests and manage sessions.
- Uses IChatWidgetService to register widget instances and retrieve last focused widget.
- Uses IInstantiationService to create content parts dynamically (ChatMarkdownContentPart, ChatTextEditContentPart, etc.)

UI patterns & primitives
- Virtualized WorkbenchObjectTree / WorkbenchList for efficient rendering of long histories.
- ContentPart pattern: the widget delegates individual message segments to IChatContentPart implementations.
- Editor pools (EditorPool, DiffEditorPool) to reuse heavyweight editor instances for embedded code and diffs.

State & Persistence
- Persists session-related state using Memento via [`src/vs/workbench/contrib/chat/browser/chatViewPane.ts:1`].
- Tracks in-widget editing state and checkpoints; integrates with chat model checkpoint APIs.

Porting considerations
- Recreate a service registry / DI for per-widget instantiation and content part factories.
- Implement or reuse a virtualized list that supports dynamic heights and content replacement (diffing).
- Provide an editor embedding strategy or lightweight alternative for code blocks and diffs.
- Implement memento-like storage semantics (workspace vs global) for session restoration.

Implementation risks
- Tight coupling between widget and workbench services (menus, context keys, command service).
- Complexity of progressive rendering/partial updates and editor embedding synchronization.

Testing notes
- Unit tests for request to response lifecycle and progressive render steps.
- Integration tests to validate memento restore and focus behavior across panel vs editor.

Cross-links
- See Chat overview: [`product_description/features/chat/overview.md:1`]
- Renderer details: [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1`]
- Input & attachments: [`src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1`]
