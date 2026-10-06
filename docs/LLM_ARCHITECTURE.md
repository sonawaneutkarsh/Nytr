# AI review boundary

Nytr's optional AI review explains a deterministic snapshot. It does not make
nutrition, target, eligibility, training, or health decisions. Deterministic
Python remains the source of every number.

There are two paths. Both read the same minimized, allowlisted snapshot.

## On-device (the path the iOS app uses)

1. The app calls `GET /v1/review/snapshot`. This endpoint returns deterministic
   owner evidence only. It has no call path to an AI provider.
2. `ios/NutritionHealthCompanion/Support/OnDeviceReview.swift` sends the
   allowlisted `ReviewModelInput` to Apple Foundation Models on the device.
   It is gated on `canImport(FoundationModels)`, iOS 26, and
   `SystemLanguageModel` availability.
3. If the model is not available, the app shows the deterministic analysis only.

Evidence does not leave the device for this path, and no API key is needed.

## Server-side Gemini (optional, disabled by default)

`backend/src/nutrition_agent/infrastructure/gemini_ai_review.py` implements the
same typed review port with the Gemini API behind `POST /v1/review/current`.
It is off unless `GEMINI_AI_REVIEW_ENABLED=true` and `GEMINI_API_KEY` are set.
The shipped iOS screens do not call this endpoint.

Missing configuration, timeout, quota, malformed output, safety refusal,
authentication failure, and outages become coarse unavailable states. The app
keeps working from deterministic data.

## Rules for both paths

- The snapshot excludes names, dates, identifiers, food rows, raw history,
  tokens, and source-provider text.
- AI output is bounded structured prose. It is not persisted and is never
  treated as evidence.
