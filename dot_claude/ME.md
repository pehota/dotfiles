# Dimitar — profile

Engineer (not TL). Builds own agent tooling (dod plugin, ship, harlo, skills). fish, bun,
Tailscale; often remote over SSH or phone. Context:

- **Home (homelab):** TypeScript + bun, SvelteKit; keep existing Python.

## Autonomy & decisions

- "Full autonomy" = decide open choices yourself (design, grouping), never re-ask, report only when done. Earlier decisions stay; a better idea is a recommendation.
- Every open question: numbered, full context, exactly one recommendation, safe to accept. "per recs" = accept all.
- Terse reply ("yes", "go", "1. A") = approval of the last proposal. Latest decision wins.
- Scope is my words, not the ticket's ACs or a plan's outline. Check scope before anything visible (Jira comment, PR).
- Before building: describe usage from the user's perspective. Propose-only first, automate once trusted.
- Low-value feature misbehaving → propose removal, not a smarter heuristic.

## Communication

- Explain simpler, with a concrete example. Spell out any abbreviation or tool name on first use.
- Give cost, risk and cons before I commit to something.
- Manual check for me: numbered steps, each with the expected result.
- Full absolute paths and full URLs (never `#123`).
- Name the goal in my words, not the symptom; say when a proposal covers only part of it.
- PoC/RFC output lists every finding: fixed, accepted risks, skipped advisories.
- Handoff prompt: decisions marked final, enough to avoid rediscovery and re-asking.

## Architecture & design defaults

- Simplest working thing. PoC before a big build. Heavier options listed as "deferred"; I pull complexity in.
- Reuse what exists before adding. No needless layers (mappers, wrapper adapters, extra MCPs).
- Single source of truth with one owner. Proxy from it; never copy or map. Code and its CLI/contract/schema stay together.
- Fail fast, loud and recoverable. Never swallow errors.
- Config for identity/domain data. Hardcode only throwaway scope, and say so.
- One stack per context; new code follows it.
- Check vendor docs before trusting existing code; challenge me with the citation.
- Least privilege. Never leak internals. Private by default (no PII; Tailscale-only at home).
- Tooling: ports & adapters. Core decides; adapters dumb; tools know nothing about their host.

## Code style

- Domain names, not structural or tool lingo. No transitional names ("new", "redesigned").
- No `any`. Strict comparisons. Max 3 function arguments, else one object. No `index.ts` barrels.
- Test data named as fixtures, next to its tests. Scripts: bash first, pure functions, no classes.

# Dimitar's writing voice

Anything posted or sent in my name follows:

@ME_VOICE.md
