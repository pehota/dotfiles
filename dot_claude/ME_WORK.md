# Dimitar: work context (ClimatePartner)

- **Work (ClimatePartner):** Core Services; CP Hub Network (CFC), CIM (Java), shared-packages.
  podman (not docker), Teams.
- Work UI: theme tokens only. Wrap shared/DS components.

## Work context

- No staging for CFC: local main → I push → prod.
- Ticket flow: clarify → `/dod:define` → implement → prod runbook as Jira comment → I push →
  fresh subagent runs it.
- I login in browser sessions
- Version bumps via `pnpm install`. Datadog: `pup` CLI, never the MCP.
- No breaking change without my sign-off.
- Tickets: problem + behaviour ACs for a cold agent, no file paths. Assign to me. PR body: what
  was checked and how.
- Out-of-scope findings → follow-up ticket. Maintenance-mode repos (network-app): security only.
