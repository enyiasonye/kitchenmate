# AI providers and cost breakdown

Research for issue #7. All prices are published list prices in USD, retrieved **2026-09-29** from the providers' own pages (linked inline and in [Sources](#sources)). Prices and model line-ups change often; re-check before committing.

## Summary

- **AI is a rounding error in the budget.** At personal volume (20-60 imports/month plus daily grocery matching), every cheap and mid-tier model costs **under $3/month even in the high scenario**. The expected case is roughly **$0.05-$0.20/month on cheap-tier models, $0.35-$1.20/month on mid-tier models, and $2.40-$6.00/month on top-tier models**. Transcription adds **$0.04-$0.36/month** in the expected case.
- **Recommendation: primary Google Gemini 3.8 Flash, fallback Anthropic Claude Sonnet 5.5, transcription on Groq `whisper-large-v3-turbo`.** Expected total about **$0.40/month in 2026 (about $0.75/month after Gemini's announced 1 January 2027 price increase)**, high scenario about **$0.90-$1.70/month**. That is roughly **2-7% of a $10-25 ceiling in the expected case, and at most about 17% of the $10 floor in the high scenario**.
- **Because price barely differs in absolute terms, choose on extraction quality, not price.** No primary source publishes a recipe-extraction benchmark; the quality ranking in this document is therefore a capability comparison, not a measured result. A small eval on the owner's own recipes (10-20 samples per import type) is the one thing that should be done before locking the choice.
- **Only Gemini covers every input type in one API** (text, images, native audio and video input, a dedicated transcription model, JSON-schema output). Anthropic and the hosted open-model providers need a separate speech-to-text service for video audio.
- **Apple on-device options are free but fit poorly** as the main engine: the on-device foundation model has a 4,096-token context window, import processing is planned to run in the cloud, and all of these are Swift-only frameworks (the owner leans React Native). Vision text recognition and `SpeechTranscriber` are reasonable optional pre-processing steps on the device.
- Top-tier models (Claude Opus 5.5, GPT-6 Astra, Claude Fable 5.1) are affordable at this volume but there is no evidence this task needs them.

## Requirements recap

Single user, iPhone + Mac clients, cloud backend, $10-25/month total including hosting. AI tasks:

1. Extract a structured recipe from web page text.
2. Extract from a social video caption.
3. Extract from a video transcript (needs speech-to-text if no caption/transcript exists).
4. Extract from 1-3 cookbook photos (vision).
5. Possibly match free-text grocery items ("waffles") to store products.

## Pricing table: language models

Standard (non-batch) tier, per 1M tokens. "Cached" is the price of reading a cached prompt prefix.

| Tier | Provider / model | Input | Output | Cached input | Batch | Vision | Audio input | Source |
|---|---|---|---|---|---|---|---|---|
| Cheap | OpenAI `gpt-6-luna` | $0.10 | $0.50 | $0.01 | 50% off | Yes | No (separate transcription models) | [OpenAI pricing][oai-price] |
| Cheap | Together AI Qwen3.8 Flash | $0.09 | $0.28 | n/a | Listed, rate not stated | Listed under Vision tab | No | [Together pricing][tog-price] |
| Cheap | Groq `openai/gpt-oss-120b` | $0.15 | $0.60 | n/a | Developer plan | No | No | [Groq models][groq-models] |
| Cheap | Mistral Small 4 | $0.15 | $0.60 | n/a | 50% off | Not confirmed | No | [Mistral pricing][mis-price] |
| Cheap | Fireworks GLM 5.3 Flash | $0.15 | $0.50 | $0.03 | 50% off | Not confirmed | No | [Fireworks pricing][fw-price] |
| Cheap | Google Gemini 3.1 Flash-Lite | $0.25 ($0.50 audio) | $1.50 | $0.025 | 50% off | Yes | Yes | [Gemini pricing][gem-price] |
| Cheap | Google Gemini 3.5 Flash-Lite | $0.30 (all modalities) | $2.50 | $0.03 | 50% off | Yes | Yes | [Gemini pricing][gem-price] |
| Mid | Google Gemini 3.8 Flash | $0.75 until 2026-12-31, then $1.50 | $3.75 until 2026-12-31, then $7.50 | $0.075, then $0.15 | 50% off | Yes | Yes | [Gemini pricing][gem-price] |
| Mid | Groq `qwen/qwen3.8-27b` (preview) | $0.80 | $4.00 | n/a | Developer plan | Yes (max 3 images) | No | [Groq models][groq-models], [Groq vision][groq-vision] |
| Mid | Anthropic Claude Haiku 4.5 | $1.00 | $5.00 | $0.10 | 50% off | Yes | No | [Anthropic pricing][ant-price] |
| Mid | Mistral Medium 3.5 | $1.50 | $7.50 | n/a | 50% off | Yes ("multimodal") | No | [Mistral pricing][mis-price], [Mistral models][mis-models] |
| Mid | OpenAI `gpt-6.1-sol` | $2.00 | $10.00 | $0.10 | 50% off | Yes | No | [OpenAI pricing][oai-price] |
| Mid | Anthropic Claude Sonnet 5.5 | $2.00 | $10.00 | $0.20 | 50% off | Yes | No | [Anthropic pricing][ant-price] |
| Mid | Google Gemini 3.1 Pro Preview | $2.00 | $12.00 | $0.20 | 50% off | Yes | Yes | [Gemini pricing][gem-price] |
| Top | Anthropic Claude Opus 5.5 | $4.00 | $20.00 | $0.20 | 50% off | Yes | No | [Anthropic pricing][ant-price] |
| Top | OpenAI `gpt-6-astra` | $10.00 | $50.00 | $1.00 | 50% off | Yes | No | [OpenAI pricing][oai-price] |
| Top | Anthropic Claude Fable 5.1 | $10.00 | $50.00 | $0.25 | 50% off | Yes | No | [Anthropic pricing][ant-price] |

Notes on the table:

- Gemini 3.8 Flash doubles in price on 1 January 2027 according to Google's own pricing page ([Gemini pricing][gem-price]). Both prices are modelled below.
- Anthropic's pricing page lists no audio or transcription price, and its vision documentation covers images only ([Anthropic pricing][ant-price], [Anthropic vision][ant-vision]). "No" for audio input on Anthropic, OpenAI text models, Mistral text models and the open-model hosts means a separate transcription call is needed.
- Anthropic states that Claude 4.7 and later models use a tokenizer that "produces approximately 30% more tokens for the same text" ([Anthropic pricing][ant-price]). The cost model applies a 1.3x multiplier to text tokens for Sonnet 5.5, Opus 5.5 and Fable 5.1, and none for Haiku 4.5.
- "Not confirmed" means the provider's page retrieved for this research did not state image input for that model; it is not a statement that the model lacks it.
- Groq lists `llama-3.1-8b-instant` and `llama-3.3-70b-versatile` as enterprise / contact-sales on its models page, so they are left out ([Groq models][groq-models]).
- Gemini has a free tier with "free input & output tokens", but content on it is "used to improve our products"; paid tier content is not ([Gemini pricing][gem-price]). Rate limits for the free tier are not published as fixed numbers; Google directs users to AI Studio ([Gemini rate limits][gem-limits]).

## Pricing table: speech-to-text

| Provider / model | Published price | Per minute | 5-minute video | Notes | Source |
|---|---|---|---|---|---|
| Apple `SpeechTranscriber` (on device) | Free | $0 | $0 | iOS/macOS 26+, Swift only, runs on the device | [Apple SpeechTranscriber][ap-st] |
| Gemini 3.5 Flash-Lite, native audio input | $0.30 / 1M tokens, 32 tokens per second | ~$0.0006 | ~$0.003 | Audio goes straight into the extraction call; no separate transcript step | [Gemini pricing][gem-price], [Gemini audio][gem-audio] |
| Groq `whisper-large-v3-turbo` | $0.04 / hour | ~$0.0007 | ~$0.003 | 10-second minimum billed per request; 25 MB max file on free tier, 100 MB on developer tier | [Groq models][groq-models], [Groq speech-to-text][groq-stt] |
| Gemini 3.8 Flash, native audio input | $0.75 / 1M tokens, 32 tokens per second | ~$0.0014 | ~$0.007 | Doubles on 2027-01-01 | [Gemini pricing][gem-price], [Gemini audio][gem-audio] |
| Together AI Whisper Large v3 | $0.0015 / minute | $0.0015 | $0.0075 | | [Together pricing][tog-price] |
| Groq `whisper-large-v3` | $0.111 / hour | ~$0.0019 | ~$0.009 | Same limits as turbo | [Groq models][groq-models] |
| AssemblyAI Universal-2 | $0.15 / hour | $0.0025 | $0.0125 | $50 free credits | [AssemblyAI pricing][aai-price] |
| OpenAI `gpt-4o-mini-transcribe` | $0.003 / minute (estimated by OpenAI) | $0.003 | $0.015 | 25 MB max file | [OpenAI pricing][oai-price], [OpenAI speech-to-text][oai-stt] |
| Mistral Voxtral Mini Transcribe 2 | $0.003 / minute | $0.003 | $0.015 | | [Mistral pricing][mis-price] |
| AssemblyAI Universal-3.5 Pro | $0.21 / hour | $0.0035 | $0.0175 | | [AssemblyAI pricing][aai-price] |
| Deepgram Nova-3 (monolingual, pre-recorded) | $0.0043 / minute | $0.0043 | $0.0215 | $200 free credit, no minimums | [Deepgram pricing][dg-price] |
| OpenAI `gpt-transcribe` | $0.0045 / minute | $0.0045 | $0.0225 | OpenAI's recommended default for recorded speech | [OpenAI pricing][oai-price], [OpenAI speech-to-text][oai-stt] |
| Deepgram Whisper Large | $0.0048 / minute | $0.0048 | $0.024 | | [Deepgram pricing][dg-price] |
| Gemini 3.5 Transcribe | ~$0.005 / minute blended | $0.005 | $0.025 | Language detection, diarization, word timestamps | [Gemini pricing][gem-price] |
| OpenAI `gpt-4o-transcribe` | $0.006 / minute | $0.006 | $0.03 | | [OpenAI pricing][oai-price] |

Fireworks' pricing pages retrieved for this research did not show a speech-to-text price, so it is omitted ([Fireworks pricing][fw-price]).

## Capability comparison

| | Anthropic | OpenAI | Google Gemini | Mistral | Groq | Together / Fireworks | Apple on-device |
|---|---|---|---|---|---|---|---|
| Structured output | JSON schema via `output_config.format`, generally available on all current models including Haiku 4.5 | Structured Outputs with JSON schema | JSON Schema subset via structured outputs | "Custom" schema and JSON modes | `strict: true` constrained decoding on `gpt-oss-20b`, `gpt-oss-120b`, `qwen3.8-27b` | Not verified in this research | Guided generation with `@Generable`, constrained sampling |
| Image input | Yes; up to 600 images per request | Yes; up to 1,500 images per request | Yes; up to 3,600 images per request | Yes on multimodal models; dedicated OCR 4.1 at $4 per 1,000 pages | Yes on `qwen3.8-27b` only, max 3 images, 2,048 tokens each | Yes on listed vision models | Vision `RecognizeTextRequest` / `RecognizeDocumentsRequest`; image prompts in Foundation Models |
| Audio input | No | Separate transcription models | Native, 32 tokens per second, up to 9.5 hours per prompt | Voxtral transcription models | Whisper models | Whisper on Together | `SpeechAnalyzer` + `SpeechTranscriber` |
| Video input | No | No (not researched further) | Native; public YouTube URLs accepted in preview at no charge | No | No | No | No |
| Batch discount | 50% | 50% | 50% | 50% | Developer plan feature | Fireworks 50% | n/a |
| Prompt caching | Cache read 0.1x input price (lower on some models) | Cached input price listed per model | Context caching price listed per model | Not listed | Available | Cached prices listed for some models | n/a |
| Rate limits at entry level | 1,000 RPM, 2M input tokens/min on Haiku 4.5 and Sonnet 5.5 | Not researched | Per-project, shown in AI Studio | Not researched | Free plan: 30 RPM, 1,000 requests/day on LLMs; Whisper 20 RPM, 2,000 requests/day, 7,200 audio seconds/hour | Not researched | Device-bound |

Sources for the rows: [Anthropic structured outputs][ant-so], [Anthropic vision][ant-vision], [Anthropic rate limits][ant-limits], [OpenAI structured outputs][oai-so], [OpenAI images and vision][oai-img], [Gemini structured outputs][gem-so], [Gemini image understanding][gem-img], [Gemini audio][gem-audio], [Gemini video][gem-video], [Mistral structured output][mis-so], [Mistral pricing][mis-price], [Groq structured outputs][groq-so], [Groq vision][groq-vision], [Groq rate limits][groq-limits], [Fireworks pricing][fw-price], [Apple guided generation][ap-gen], [Apple RecognizeTextRequest][ap-rt], [Apple RecognizeDocumentsRequest][ap-rd], [Apple SpeechAnalyzer][ap-sa], [Apple image prompting][ap-img].

Details that matter for KitchenMate:

- **Structured output limits.** Anthropic's schema support excludes recursive schemas and numeric or string length constraints, and caps optional parameters at 24 across all schemas ([Anthropic structured outputs][ant-so]). Groq strict mode requires every field to be `required` and `additionalProperties: false` ([Groq structured outputs][groq-so]). Gemini warns that output is syntactically valid JSON but values must still be validated ([Gemini structured outputs][gem-so]). A recipe schema (title, servings, times, ingredient list, steps) is simple enough for all of them, but optional fields should be modelled as nullable rather than optional to stay portable.
- **Gemini's own structured-output documentation uses a recipe extractor as its first example** ([Gemini structured outputs][gem-so]). This shows the use case is a mainstream one, not that Gemini is better at it.
- **Image token cost differs by provider.** Anthropic charges `ceil(width/28) x ceil(height/28)` tokens, capped at 1,568 tokens on Haiku 4.5 and 4,784 tokens on Claude 4.7-and-later models ([Anthropic vision][ant-vision]). OpenAI charges 32-pixel patches times a model multiplier (1.2 for the current models listed), with a 2,500-patch budget at high detail ([OpenAI images and vision][oai-img]). Gemini charges 258 tokens per 768x768 tile ([Gemini image understanding][gem-img]). Groq charges a flat 2,048 tokens per image ([Groq vision][groq-vision]).
- **Video.** Gemini tokenizes video at roughly 100 tokens per second at default resolution and 300 at high resolution ([Gemini video][gem-video]), so a 5-minute video is about 30,000-90,000 input tokens: $0.02-$0.07 on Gemini 3.8 Flash at 2026 prices. Sending only the audio track (1,920 tokens per minute) is about ten times cheaper. Whether social video files can be obtained at all is outside this ticket.

## Apple on-device options

| Option | What it does | Availability | Fit |
|---|---|---|---|
| Vision `RecognizeTextRequest` | Recognizes text in an image | iOS 18+, macOS 15+ | Free OCR of cookbook photos on the device; produces text, not a recipe |
| Vision `RecognizeDocumentsRequest` | Extracts document structure: paragraphs, tables, lists | iOS 26+, macOS 26+ | Better for cookbook pages because lists and tables are preserved |
| Speech `SpeechAnalyzer` + `SpeechTranscriber` | On-device speech-to-text from files or buffers | iOS 26+, macOS 26+ | Free transcription if the audio is on the device |
| Foundation Models, on-device model | Text and image prompts with guided generation into Swift types | iOS 26+, macOS 26+, Apple Intelligence devices only | Context window is 4,096 tokens per session including schema and output, which is too small for most web pages and long transcripts |
| Foundation Models via Private Cloud Compute | Server model with a 32K-token context, no API keys | iOS 27+, macOS 27+; managed entitlement; per-person daily request limit | Free to the developer, but access requires eligibility approval and quota is tied to the person's iCloud plan |

Sources: [Apple RecognizeTextRequest][ap-rt], [Apple RecognizeDocumentsRequest][ap-rd], [Apple SpeechAnalyzer][ap-sa], [Apple SpeechTranscriber][ap-st], [Apple Foundation Models][ap-fm], [Apple context window][ap-ctx], [Apple Private Cloud Compute][ap-pcc], [Apple image prompting][ap-img].

Constraints specific to this project:

- The map (issue #1) places import processing in the cloud. Apple's frameworks run only on the device, so using them means the device does part of the import work before or instead of the backend.
- They are Swift APIs. With React Native they need a native module; with SwiftUI they are directly usable.
- They save very little money here: the cloud cost they would replace is cents per month.

## Cost model

### Assumptions

These are planning assumptions made for this research, not provider figures, except where a source is given.

| Item | Assumption | Basis |
|---|---|---|
| System prompt plus JSON schema | 800 input tokens per call | Estimate |
| Web page | 3,000 tokens of cleaned main-content text (high scenario: 8,000) | Anthropic gives about 2,500 tokens for an average 10 kB web page ([Anthropic pricing][ant-price]); assumes HTML is stripped to text first |
| Social caption | 400 tokens | Estimate |
| Video transcript | 200 tokens per minute of speech, plus the 400-token caption | Google's pricing note uses 175 text tokens per minute of transcribed audio ([Gemini pricing][gem-price]); rounded up |
| Cookbook photo | 2,500 input tokens per photo, photos downscaled on the client to about 1,568 px on the long edge | Conservative across the provider formulas above; an unscaled photo on a high-resolution Claude model can reach 4,784 tokens ([Anthropic vision][ant-vision]) |
| Recipe output | 1,000 tokens (caption 800, photos 1,200) | Estimate |
| Grocery matching | One call per day: 500 tokens of instructions plus 250 input tokens per item (the item and about five candidate products), 40 output tokens per item | Estimate; assumes candidates come from a store search, not from the model |
| Reasoning tokens | None | Providers bill reasoning as output ([Gemini pricing][gem-price]); assumes reasoning is off or minimal. Doubling output tokens raises totals by roughly 50-60% |
| Claude tokenizer | 1.3x text tokens on Sonnet 5.5, Opus 5.5, Fable 5.1 | [Anthropic pricing][ant-price] |
| Caching and batch discounts | Not applied | Calls are small and interactive; discounts would only lower these numbers |

Monthly scenarios:

| Scenario | Imports | Mix | Video length | Photos per photo import | Grocery items per day | Retry overhead |
|---|---|---|---|---|---|---|
| Low | 20 | 8 web, 4 caption, 6 video, 2 photo | 2 minutes | 1 | 5 | none |
| Expected | 40 | 16 web, 8 caption, 12 video, 4 photo | 5 minutes | 2 | 10 | none |
| High | 60 | 24 web (8,000-token pages), 12 caption, 18 video, 6 photo | 10 minutes | 3 | 15 | +25% |

Transcription minutes per month: 12 (low), 60 (expected), 180 (high).

### Per-import cost

USD per import, language model only. Add transcription from the speech-to-text table for video imports without a usable caption or transcript.

| Tier | Model | Web page | Caption | Video 1 min | Video 5 min | Video 10 min | 1 photo | 2 photos | 3 photos | Grocery, 10 items |
|---|---|---|---|---|---|---|---|---|---|---|
| Cheap | Together Qwen3.8 Flash | $0.0006 | $0.0003 | $0.0004 | $0.0005 | $0.0006 | $0.0006 | $0.0009 | $0.0011 | $0.0004 |
| Cheap | OpenAI `gpt-6-luna` | $0.0009 | $0.0005 | $0.0006 | $0.0007 | $0.0008 | $0.0009 | $0.0012 | $0.0014 | $0.0005 |
| Cheap | Groq `gpt-oss-120b` / Mistral Small 4 | $0.0012 | $0.0007 | $0.0008 | $0.0009 | $0.0011 | n/a | n/a | n/a | $0.0007 |
| Cheap | Gemini 3.1 Flash-Lite | $0.0024 | $0.0015 | $0.0019 | $0.0021 | $0.0023 | $0.0026 | $0.0032 | $0.0039 | $0.0014 |
| Cheap | Gemini 3.5 Flash-Lite | $0.0036 | $0.0024 | $0.0029 | $0.0032 | $0.0035 | $0.0040 | $0.0047 | $0.0055 | $0.0019 |
| Mid | Gemini 3.8 Flash (2026) | $0.0066 | $0.0039 | $0.0048 | $0.0054 | $0.0062 | $0.0070 | $0.0089 | $0.0107 | $0.0037 |
| Mid | Groq `qwen3.8-27b` | $0.0070 | $0.0042 | $0.0051 | $0.0058 | $0.0066 | $0.0074 | $0.0094 | $0.0114 | $0.0040 |
| Mid | Claude Haiku 4.5 | $0.0088 | $0.0052 | $0.0064 | $0.0072 | $0.0082 | $0.0093 | $0.0118 | $0.0143 | $0.0050 |
| Mid | Gemini 3.8 Flash (2027) / Mistral Medium 3.5 | $0.0132 | $0.0078 | $0.0096 | $0.0108 | $0.0123 | $0.0140 | $0.0177 | $0.0215 | $0.0075 |
| Mid | OpenAI `gpt-6.1-sol` | $0.0176 | $0.0104 | $0.0128 | $0.0144 | $0.0164 | $0.0186 | $0.0236 | $0.0286 | $0.0100 |
| Mid | Gemini 3.1 Pro Preview | $0.0196 | $0.0120 | $0.0148 | $0.0164 | $0.0184 | $0.0210 | $0.0260 | $0.0310 | $0.0108 |
| Mid | Claude Sonnet 5.5 | $0.0229 | $0.0135 | $0.0166 | $0.0187 | $0.0213 | $0.0227 | $0.0277 | $0.0327 | $0.0130 |
| Top | Claude Opus 5.5 | $0.0458 | $0.0270 | $0.0333 | $0.0374 | $0.0426 | $0.0454 | $0.0554 | $0.0654 | $0.0260 |
| Top | OpenAI `gpt-6-astra` | $0.0880 | $0.0520 | $0.0640 | $0.0720 | $0.0820 | $0.0930 | $0.1180 | $0.1430 | $0.0500 |
| Top | Claude Fable 5.1 | $0.1144 | $0.0676 | $0.0832 | $0.0936 | $0.1066 | $0.1134 | $0.1384 | $0.1634 | $0.0650 |

### Monthly cost

USD per month, imports plus daily grocery matching, language model only.

| Tier | Model | Low | Expected | High |
|---|---|---|---|---|
| Cheap | Together Qwen3.8 Flash | $0.02 | $0.03 | $0.08 |
| Cheap | OpenAI `gpt-6-luna` | $0.02 | $0.05 | $0.11 |
| Cheap | Groq `gpt-oss-120b` / Mistral Small 4 (photos not included) | $0.03 | $0.06 | $0.14 |
| Cheap | Gemini 3.1 Flash-Lite | $0.06 | $0.13 | $0.29 |
| Cheap | Gemini 3.5 Flash-Lite | $0.10 | $0.19 | $0.41 |
| Mid | Gemini 3.8 Flash (2026 price) | $0.17 | $0.35 | $0.79 |
| Mid | Groq `qwen3.8-27b` | $0.19 | $0.37 | $0.84 |
| Mid | Claude Haiku 4.5 | $0.23 | $0.47 | $1.06 |
| Mid | Gemini 3.8 Flash (2027 price) / Mistral Medium 3.5 | $0.35 | $0.70 | $1.58 |
| Mid | OpenAI `gpt-6.1-sol` | $0.46 | $0.93 | $2.11 |
| Mid | Gemini 3.1 Pro Preview | $0.52 | $1.03 | $2.30 |
| Mid | Claude Sonnet 5.5 | $0.60 | $1.20 | $2.71 |
| Top | Claude Opus 5.5 | $1.20 | $2.40 | $5.42 |
| Top | OpenAI `gpt-6-astra` | $2.32 | $4.66 | $10.56 |
| Top | Claude Fable 5.1 | $3.00 | $6.00 | $13.55 |

Grocery matching is about one third of each total. If resolved item mappings are stored and reused, that share falls towards zero after the first weeks.

Transcription, USD per month:

| Service | Low (12 min) | Expected (60 min) | High (180 min) |
|---|---|---|---|
| Apple `SpeechTranscriber` on device | $0 | $0 | $0 |
| Gemini 3.5 Flash-Lite native audio | $0.01 | $0.03 | $0.10 |
| Groq `whisper-large-v3-turbo` | $0.01 | $0.04 | $0.12 |
| Gemini 3.8 Flash native audio (2026 price) | $0.02 | $0.09 | $0.26 |
| Together Whisper Large v3 | $0.02 | $0.09 | $0.27 |
| AssemblyAI Universal-2 | $0.03 | $0.15 | $0.45 |
| OpenAI `gpt-4o-mini-transcribe` / Mistral Voxtral Mini Transcribe 2 | $0.04 | $0.18 | $0.54 |
| Deepgram Nova-3 | $0.05 | $0.26 | $0.77 |
| OpenAI `gpt-transcribe` | $0.05 | $0.27 | $0.81 |
| OpenAI `gpt-4o-transcribe` | $0.07 | $0.36 | $1.08 |

Deepgram's $200 and AssemblyAI's $50 free credits would each cover years of transcription at this volume ([Deepgram pricing][dg-price], [AssemblyAI pricing][aai-price]).

### Totals by tier

Language model plus transcription, USD per month:

| Tier | Example stack | Low | Expected | High | Share of $10 ceiling (expected / high) | Share of $25 ceiling (expected / high) |
|---|---|---|---|---|---|---|
| Cheap | Gemini 3.5 Flash-Lite, native audio | $0.10 | $0.22 | $0.52 | 2% / 5% | 1% / 2% |
| Mid (recommended) | Gemini 3.8 Flash at 2026 price + Groq Whisper turbo | $0.18 | $0.39 | $0.91 | 4% / 9% | 2% / 4% |
| Mid (recommended, 2027 price) | Gemini 3.8 Flash at 2027 price + Groq Whisper turbo | $0.36 | $0.74 | $1.70 | 7% / 17% | 3% / 7% |
| Mid (fallback as primary) | Claude Sonnet 5.5 + Groq Whisper turbo | $0.61 | $1.24 | $2.83 | 12% / 28% | 5% / 11% |
| Top | Claude Opus 5.5 + OpenAI `gpt-transcribe` | $1.25 | $2.67 | $6.23 | 27% / 62% | 11% / 25% |

## Recommendation

**Primary: Google Gemini 3.8 Flash on the paid tier.**

- It is the only provider researched whose single API accepts every KitchenMate input type, including audio and video, and has JSON-schema output.
- Expected cost is about $0.35/month in 2026 and about $0.70/month after the announced January 2027 increase.
- The paid tier's content is not used to improve Google's products; the free tier's is ([Gemini pricing][gem-price]).

**Fallback: Anthropic Claude Sonnet 5.5**, used when the primary is unavailable or returns a result that fails validation. Schema-constrained output is generally available and the cost would still be about $1.20/month if it handled everything. Claude Haiku 4.5 is the cheaper alternative at about $0.47/month.

**Transcription: Groq `whisper-large-v3-turbo`** at about $0.04/month expected, or Gemini native audio input in the same call as extraction. Groq's free plan limits (20 requests/minute, 2,000 requests/day, 7,200 audio seconds/hour) already exceed this volume ([Groq rate limits][groq-limits]).

**Grocery matching:** use the same primary model, or a cheap-tier model such as Gemini 3.5 Flash-Lite or `gpt-6-luna`. Store confirmed mappings so the model is only called for items it has not seen.

**Apple on-device:** optional. Vision OCR before upload and `SpeechTranscriber` for audio already on the device are free, but they add native code and save only cents.

**Share of the ceiling:** about $0.40-$1.25/month expected, which is 4-12% of $10 and 2-5% of $25. The high scenario stays under $3/month for every cheap and mid-tier option. Hosting, not AI, will decide whether the app fits the budget.

**What would change this recommendation:**

- An eval on real recipes showing that a different model extracts noticeably better. The price difference between any two mid-tier models is under $1/month, so quality should win.
- A decision to keep the whole stack on one vendor's billing account.
- A decision to build in SwiftUI and move import processing onto the device, which would make the Apple frameworks more attractive.

## Open questions

1. **Extraction quality is unmeasured.** No primary source compares these models on recipe extraction. A small eval set is needed.
2. **Getting the audio or transcript of a social video** (Instagram, TikTok, YouTube) is a separate technical and terms-of-service question. Gemini accepts public YouTube URLs directly, in preview and currently at no charge ([Gemini video][gem-video]); other platforms are not covered.
3. **Minimum top-ups and prepayment.** Minimum credit purchases for each provider were not verified in this research. With spend this low, a minimum prepaid balance could last many months.
4. **Image input on Mistral Small 4, Together Qwen3.8 Flash and Fireworks GLM 5.3 Flash** was not confirmed from the pages retrieved.
5. **OpenAI's image-token multiplier for `gpt-6-luna` and `gpt-6.1-sol`** is not in the published multiplier table, which lists `gpt-6-astra` and older models at 1.2 ([OpenAI images and vision][oai-img]). The model assumes a flat 2,500 tokens per photo instead.
6. **Reasoning tokens.** If a chosen model reasons by default, output tokens and cost will be higher than modelled. This should be measured during the eval.
7. **Whether grocery matching needs a model at all** once item mappings exist depends on the item mapping design, which is a separate ticket.

## Sources

All retrieved 2026-09-29.

- [Anthropic pricing][ant-price]
- [Anthropic vision][ant-vision]
- [Anthropic structured outputs][ant-so]
- [Anthropic rate limits][ant-limits]
- [OpenAI pricing][oai-price]
- [OpenAI structured outputs][oai-so]
- [OpenAI images and vision][oai-img]
- [OpenAI speech-to-text][oai-stt]
- [Gemini pricing][gem-price]
- [Gemini rate limits][gem-limits]
- [Gemini structured outputs][gem-so]
- [Gemini image understanding][gem-img]
- [Gemini audio understanding][gem-audio]
- [Gemini video understanding][gem-video]
- [Mistral pricing][mis-price]
- [Mistral models overview][mis-models]
- [Mistral structured output][mis-so]
- [Groq models and pricing][groq-models]
- [Groq rate limits][groq-limits]
- [Groq speech-to-text][groq-stt]
- [Groq structured outputs][groq-so]
- [Groq vision][groq-vision]
- [Together AI pricing][tog-price]
- [Fireworks serverless pricing][fw-price]
- [Deepgram pricing][dg-price]
- [AssemblyAI pricing][aai-price]
- [Apple Foundation Models][ap-fm]
- [Apple guided generation][ap-gen]
- [Apple managing the context window][ap-ctx]
- [Apple Private Cloud Compute][ap-pcc]
- [Apple image prompting][ap-img]
- [Apple SpeechAnalyzer][ap-sa]
- [Apple SpeechTranscriber][ap-st]
- [Apple RecognizeTextRequest][ap-rt]
- [Apple RecognizeDocumentsRequest][ap-rd]

[ant-price]: https://platform.claude.com/docs/en/about-claude/pricing
[ant-vision]: https://platform.claude.com/docs/en/build-with-claude/vision
[ant-so]: https://platform.claude.com/docs/en/build-with-claude/structured-outputs
[ant-limits]: https://platform.claude.com/docs/en/api/rate-limits
[oai-price]: https://developers.openai.com/api/docs/pricing
[oai-so]: https://developers.openai.com/api/docs/guides/structured-outputs
[oai-img]: https://developers.openai.com/api/docs/guides/images-vision
[oai-stt]: https://developers.openai.com/api/docs/guides/speech-to-text
[gem-price]: https://ai.google.dev/gemini-api/docs/pricing
[gem-limits]: https://ai.google.dev/gemini-api/docs/rate-limits
[gem-so]: https://ai.google.dev/gemini-api/docs/structured-output
[gem-img]: https://ai.google.dev/gemini-api/docs/image-understanding
[gem-audio]: https://ai.google.dev/gemini-api/docs/audio
[gem-video]: https://ai.google.dev/gemini-api/docs/video-understanding
[mis-price]: https://mistral.ai/pricing/api/
[mis-models]: https://docs.mistral.ai/getting-started/models/models_overview/
[mis-so]: https://docs.mistral.ai/capabilities/structured_output/custom_structured_output
[groq-models]: https://console.groq.com/docs/models
[groq-limits]: https://console.groq.com/docs/rate-limits
[groq-stt]: https://console.groq.com/docs/speech-to-text
[groq-so]: https://console.groq.com/docs/structured-outputs
[groq-vision]: https://console.groq.com/docs/vision
[tog-price]: https://www.together.ai/pricing
[fw-price]: https://docs.fireworks.ai/serverless/pricing
[dg-price]: https://deepgram.com/pricing
[aai-price]: https://www.assemblyai.com/pricing
[ap-fm]: https://developer.apple.com/documentation/foundationmodels
[ap-gen]: https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation
[ap-ctx]: https://developer.apple.com/documentation/foundationmodels/managing-the-context-window
[ap-pcc]: https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute
[ap-img]: https://developer.apple.com/documentation/foundationmodels/analyzing-images-with-multimodal-prompting
[ap-sa]: https://developer.apple.com/documentation/speech/speechanalyzer
[ap-st]: https://developer.apple.com/documentation/speech/speechtranscriber
[ap-rt]: https://developer.apple.com/documentation/vision/recognizetextrequest
[ap-rd]: https://developer.apple.com/documentation/vision/recognizedocumentsrequest
