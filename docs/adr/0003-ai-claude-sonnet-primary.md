# 3. AI: Claude Sonnet 5.5 as primary, paid from plan API credits

Date: 2026-10-24
Status: Accepted
Supersedes: the AI section of [ADR 2](0002-backend-supabase-free-gemini-free.md)

## Context

[ADR 2](0002-backend-supabase-free-gemini-free.md) chose Gemini Flash on the free tier because it cost nothing, and rejected Claude because the owner's Claude plan did not include API access.

The owner's Claude plan now includes $100/month in Claude API credits. [AI provider comparison and cost breakdown](https://github.com/enyiasonye/kitchenmate/issues/7) estimated Claude Sonnet 5.5 at about $1.20/month expected and $2.71/month in the high scenario. Even Claude Fable 5.1 tops out around $13.55/month. With the credits, AI cost no longer separates the providers. The research found that extraction quality, not price, should decide, and it also recommended Sonnet 5.5 as the fallback.

## Decision

- **Claude Sonnet 5.5 (`claude-sonnet-5-5`) via the Claude API** for recipe extraction (web page, caption, transcript, cookbook photos) and grocery matching, using JSON-schema structured output. It is billed against the plan's API credits.
- **Groq `whisper-large-v3-turbo` on the free plan** for transcription, unchanged. Claude does not accept audio or video, so video imports always produce a transcript before extraction. _Note: [ADR 4](0004-import-pipeline-sanctioned-sources.md) keeps V1 to sanctioned sources with no transcripts or audio, so Whisper is not used in V1._
- **Gemini Flash (free tier) is an optional fallback**, not built for V1. AI stays behind one backend interface, so a Gemini adapter is one adapter plus config. Until then, a failed extraction shows in the import review form as "retry or fill in by hand", as in ADR 2.
- **The planned extraction eval** (10–20 real recipes per import type) runs Sonnet 5.5 and Gemini Flash side by side. If Gemini is clearly better at some import type, we reopen this decision. Haiku 4.5 is also tried for grocery matching, where a cheaper model may be good enough.
- The Anthropic API key lives only in Edge Function secrets, like every other third-party key in ADR 2.

## Consequences

- Expected AI cost of about $1–3/month is covered by the credits, so out-of-pocket AI cost stays at $0.
- Free-tier data use is no longer a concern: content sent to the Claude API is not used to train models by default.
- The AI depends on the Claude plan staying active. Credit expiry, overage behavior and a Console spend limit have not been checked, and the owner deferred those checks.
- Gemini's direct YouTube-URL input is no longer available; YouTube imports need a transcript or audio fetched first, which the import pipeline decides.
- Anthropic's structured outputs exclude recursive schemas and length constraints, and allow at most 24 optional parameters. Recipe fields stay nullable rather than optional, as ADR 2 already required.

## Rejected

- **Gemini Flash free tier as primary** (ADR 2): its main advantage was price, which the credits remove.
- **Claude Opus 5.5 or Fable 5.1**: affordable within the credits, but nothing yet shows this task needs them. Revisit if the eval shows Sonnet falling short.
