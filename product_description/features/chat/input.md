# Chat — Input

Purpose
- The chat input is the user's primary entry point for composing requests and driving the assistant. It supports a code-aware input editor, history navigation, mode switching (Ask/Edit/Agent), attachments toolbar, prompt-file insertion, implicit context, and local input history.

Responsibilities
- Host an embedded code editor (CodeEditorWidget) configured for lightweight editing and language-aware completions.
- Provide toolbar/menu integration for model selection, mode switching, and send actions.
- Manage attachments UI (file/image/paste/prompt files/tool selections) and wire deletion/open actions.
- Maintain per-widget input history and expose navigation (previous/next).
- Expose editing mode and integrate with the chat editing pipeline (edit requests inline/hover/input).
- Coordinate with ChatWidget to trigger send/resend flows and to accept parsed inputs (variables, tool invocations).

Key implementation files
- [`src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatWidget.ts:1`](src/vs/workbench/contrib/chat/browser/chatWidget.ts:1)
- Attachment widgets and factories:
  - [`src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1)
  - Attachment model: [`src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentModel.ts:1)

UI patterns & primitives to reimplement
- Simple code editor embedding with options tuned for small multiline input (getSimpleCodeEditorWidgetOptions).
- Toolbar driven by MenuWorkbenchToolBar + MenuId integrations for actions and inline menus.
- Attachment chip bar with focus/keyboard support and drag/drop + context menu actions.
- Scoped context keys for input-scoped menus and state (IContextKeyService.createScoped).

State & persistence
- Input history persisted via IChatWidgetHistoryService and local mementos; last-used model/mode persisted via storage keys (e.g., `chat.currentLanguageModel.{location}`, `chat.lastChatMode`).
- Temporary parsed input state used to render detected commands/agents and provide inline command parts.

Porting checklist (input)
- Recreate a small embeddable editor with:
  - language-aware modes, basic completions, and ability to extract text/selection
  - keyboard bindings for send, history navigation (up/down), and multi-line entry
- Implement attachments bar:
  - small components/widgets for File, Image, Paste, PromptFile and ToolSet attachments
  - drag/drop and context menu integration
- Implement Menu/Toolbar abstraction or map to target platform equivalents for model/mode menus
- Recreate input-scoped context keys and menu filtering logic
- Implement input-history persistence and navigation API

Testing notes
- Unit tests for:
  - input editor rendering, send keybindings, and history navigation
  - attachment addition/removal and drag/drop behavior
  - mode switching and toolbar actions mapping to command execution
- Integration tests for:
  - compose → send → progressive response rendering interaction with ChatWidget
  - editing flows (inline/hover/input modes)

Cross-links
- Widget composition: [`product_description/features/chat/widget.md:1`](product_description/features/chat/widget.md:1)
- Markdown & rendering: [`src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1)
- Attachments: [`product_description/features/chat/attachments_and_tools.md:1`](product_description/features/chat/attachments_and_tools.md:1)
