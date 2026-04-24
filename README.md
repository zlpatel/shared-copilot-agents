# shared-copilot-agents

Cross-team, reusable GitHub Copilot agents for Broadridge engineering. These agents are team-agnostic and designed to work across any Broadridge workspace without modification.

## What's Here

```
.github/
  agents/
    copilot-agent-architect.agent.md       # Designs, creates, and reviews Copilot customization files
  hooks/
    validate-frontmatter.json              # Auto-validates YAML frontmatter after edits
    scripts/
      validate-frontmatter.ps1             # PowerShell validation script
  prompts/
    audit-agent-portfolio.prompt.md        # One-command portfolio health check
  skills/
    agent-templates/
      SKILL.md                             # Scaffold new agents from reusable templates
      references/
        service-engineer.md                # Engineer agent template
        code-review.md                     # Code review agent template
        product-owner.md                   # Product owner agent template
        solution-architect.md              # Architect agent template
        research.md                        # Research-only agent template
```

## Usage

Add this repo as a workspace folder in VS Code alongside your team's repo. Agents in `.github/agents/` are automatically picked up by GitHub Copilot.

```
File > Add Folder to Workspace... → select shared-copilot-agents
```

Once added, agents appear in the Copilot agent picker (`@` in chat).

---

## Agents

### `copilot-agent-architect`

A meta-agent that designs, creates, reviews, and optimizes VS Code Copilot customization files — agents, instructions, skills, prompts, hooks, and agent knowledge bases. It possesses deep knowledge of every tool, workflow, and behavioral pattern in the Copilot ecosystem and serves as an unbiased brainstorming partner who always leans towards the best solution and proactively raises concerns before they become problems.

**Use when:**
- Creating a new agent, instruction file, skill, prompt, or hook
- Brainstorming agent design — exploring alternatives, challenging assumptions, surfacing edge cases
- Reviewing existing customizations for anti-patterns, context waste, or cross-agent contamination
- Deciding where agent-scoped knowledge belongs (instructions vs. skills vs. plain reference files)
- Planning an agent portfolio for a new team
- Troubleshooting why an agent or instruction is not being loaded or invoked
- Optimizing context window budget across a workspace
- Designing MCP server integrations — scoping tools, reducing latency, improving tool descriptions
- Getting an honest, unbiased assessment of your current setup

**Model:** Claude Opus 4.6 (fallback: Claude Sonnet 4.6)

**Tools:** read, search, edit, web, execute, agent, todo

**Example prompts:**
- `@copilot-agent-architect Create a code review agent for our Java microservices team`
- `@copilot-agent-architect Review all agents and instructions in this workspace for anti-patterns`
- `@copilot-agent-architect I have a 600-line instruction file covering conventions, integrations, and platform architecture — should I split it?`
- `@copilot-agent-architect I have agent-specific knowledge that keeps leaking into other agents via instruction keyword matching — how should I restructure it?`
- `@copilot-agent-architect My agent calls the JIRA MCP server too many times — how can I reduce the round-trips?`

---

## Prompts

### `/audit-agent-portfolio`

Runs a comprehensive health check across all agents, instructions, skills, prompts, and hooks in the workspace. Discovers all customization files, analyzes context budget, scans for anti-patterns, and produces a structured findings report with severity ratings.

**Example:** Type `/audit-agent-portfolio` in Copilot chat.

---

## Skills

### `/agent-templates`

Scaffolds new `.agent.md` files from proven templates. Includes 5 templates with placeholders for team-specific customization:

- **Service Engineer** — Feature implementation, unit testing, builds
- **Code Review** — Read-only structured code review
- **Product Owner** — JIRA stories, acceptance criteria, backlog
- **Solution Architect** — Technical design, trade-off analysis, security
- **Research** — Read-only codebase exploration and Q&A

**Example:** Type `/agent-templates` in Copilot chat, then specify which template you need.

---

## Hooks

### `validate-frontmatter`

Automatically validates YAML frontmatter after any file edit. Checks `.agent.md`, `.instructions.md`, `.prompt.md`, and `SKILL.md` files for:

- Missing or empty `description` field
- Unquoted descriptions containing colons
- Tabs in frontmatter
- Skill `name` field not matching folder name
- `applyTo: "**"` on files over 200 lines
- Agents with 8+ tools (Swiss-army pattern)

Runs automatically — no user action required.

---

## Adding Agents to This Repo

Place new agent files at `.github/agents/<name>.agent.md`. Agents here should be:

- **Team-agnostic** — no hardcoded team names, repos, or tech stacks
- **Broadly reusable** — applicable across multiple Broadridge teams and workspaces
- **Self-contained** — all context dynamically discovered at runtime, not hardcoded

Team-specific agents belong in their team's own agent repo, not here.
