# Chat — Agents and Prompts

Purpose
- Describe how Chat selects language models (agents), presents agent metadata, supports prompt files and prompt parsing, and wires tools/toolsets to agents. This surface includes agent selection persistence, entitlement/experiment gating, and agent-level features (issue reporting, instruction-following, code-generation hints).

Responsibilities
- Provide agent selection UI and persist last-used model per location and session.
- Expose agent metadata (display name, icons, capabilities like vision) to render avatars and tooltips.
- Detect agent-invoked commands and slash-commands inside responses and requests.
- Parse and resolve prompt files (prompt templates, variables, nested references) and provide prompt-file attachments and insertion into input.
- Wire toolsets and tools (ILanguageModelToolsService) to enable tool invocation content parts and attachments.

Key implementation files and entry points
- Agent & selection UI:
  - [`src/vs/workbench/contrib/chat/browser/chatWidget.ts:1`](src/vs/workbench/contrib/chat/browser/chatWidget.ts:1)
  - [`src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1)
  - [`src/vs/workbench/contrib/chat/browser/chatAgentHover.ts:1`](src/vs/workbench/contrib/chat/browser/chatAgentHover.ts:1)
- Agent metadata & services:
  - [`src/vs/workbench/contrib/chat/common/chatAgents.ts:1`](src/vs/workbench/contrib/chat/common/chatAgents.ts:1)
  - [`src/vs/workbench/contrib/chat/common/languageModels.ts:1`](src/vs/workbench/contrib/chat/common/languageModels.ts:1)
  - Tool service: [`src/vs/workbench/contrib/chat/common/languageModelToolsService.ts:1`](src/vs/workbench/contrib/chat/common/languageModelToolsService.ts:1)
- Prompt files & parsing:
  - Prompt file locations / utilities: [`src/vs/workbench/contrib/chat/common/promptSyntax/config/promptFileLocations.ts:1`](src/vs/workbench/contrib/chat/common/promptSyntax/config/promptFileLocations.ts:1)
  - Prompts service interface: [`src/vs/workbench/contrib/chat/common/prompts.ts:1`](src/vs/workbench/contrib/chat/common/prompts.ts:1) (implements IPromptsService)
  - Prompt-file attachment widget integration: [`src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1`](src/vs/workbench/contrib/chat/browser/chatAttachmentWidgets.ts:1)

Runtime services & dependencies
- ILanguageModelsService — model discovery, metadata and capabilities.
- ILanguageModelToolsService — tool and toolset metadata and wiring to UI.
- IPromptsService — prompt file parsing, expansion, and variable resolution.
- Experimentation & entitlement checks — feature gating for agent capabilities and telemetry hooks.

User flows and behavior
- Model selection:
  - Users pick a model via input-toolbar or top widget menu; last-used model is persisted by location (panel/editor).
  - Agent icons and hover metadata are shown in message headers via [`src/vs/workbench/contrib/chat/browser/chatAgentHover.ts:1`].
- Slash commands / detected agent commands:
  - Responses can detect agent-invoked commands and show inline rerun/disable actions (rendered by list renderer and command parts).
- Prompt files:
  - Prompt files are discovered via configured prompt locations; prompt-file attachments appear in the attachment bar and can be inserted into the input.
  - Prompt files may reference other files/variables — resolution and errors surface in the prompt attachment hover and may mark attachments as omitted/partial.
- Toolsets:
  - ToolSets and Tools are surfaced as attachment widgets or as result content parts (toolInvocation) that can produce further interactive UI and embedded editors.

Porting checklist (agents & prompts)
- Implement a model registry API (ILanguageModelsService) that:
  - Enumerates available models, their capabilities (vision, tools), icons and metadata.
  - Persists last-selected model per-location (workspace/global storage).
- Implement a tool/service registry (ILanguageModelToolsService) that:
  - Exposes ToolSets and Tools by id and provides metadata for UI rendering and hover text.
- Implement prompt-file discovery & parsing (IPromptsService):
  - Support prompt file formats used by the codebase (templating, variable placeholders).
  - Implement safe resolution pipeline for nested references and errors with helpful diagnostics.
- Recreate agent entitlement and experiment gating system or map to your platform's feature flags.
- Ensure hover/tooltip and menu wiring for agent metadata and actions (e.g., report issue).

Risks & open questions
- Prompt file formats and nested resolution can be complex and depend on extension-provided prompt locations — need to decide supported subset.
- Tool invocation semantics depend on external tool implementations (e.g., SCM, notebooks) — may require adapter layers.
- Model capabilities (vision, tool access) must be normalized across providers for consistent UI behavior.

Testing
- Unit tests for:
  - Model registry enumeration and persistence of last-selected model.
  - Prompt parser: template expansion, variable substitution, error conditions and omitted-state handling.
  - Toolset registry: lookup and metadata correctness.
- Integration tests:
  - End-to-end prompt-file insertion → sendRequest → tool invocation flows.
  - Agent detection of commands and rerun-without-agent flows.

Cross-links
- Chat overview: [`product_description/features/chat/overview.md:1`](product_description/features/chat/overview.md:1)
- Input & attachments: [`product_description/features/chat/input.md:1`](product_description/features/chat/input.md:1)
- Attachments & tools: [`product_description/features/chat/attachments_and_tools.md:1`](product_description/features/chat/attachments_and_tools.md:1)
