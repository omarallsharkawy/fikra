# Authentication layout refinement

## Scope

Refine the mobile welcome, sign-in, registration, email verification, password recovery, acknowledgment and reset screens. This replaces the proposed additional animation pass, which was canceled before delivery. Existing shared press feedback and route transitions remain as previously shipped.

## Presentation

- Use a shared account-specific layout: compact brand/back row, stage icon, full wrapping heading, short localized instruction, input group, primary action, then secondary links.
- Keep form content within 480 dp with 24 dp horizontal padding. One scroll view resizes above the keyboard; no fixed form heights or nested scrolling. Stage changes create a fresh scroll/focus scope so the next heading starts in view.
- Keep Inter for English and the existing Noto Arabic font. Support RTL, light/dark themes and 2x text. Email and action-token values remain LTR independently of the interface language.
- Place the sign-in recovery link beside the password group; provide account switching below the primary action and a top back action. Hide the editable email field after recovery has been acknowledged.
- Group welcome artwork with rounded clipping, centered heading and description, and consistent action spacing. Artwork is static.
- Keep preview disclosures accessible below the main account actions. Google sign-in remains explicitly unavailable in this preview.
- Provide email/password autofill hints and Next/Done keyboard actions without automatically submitting credentials. Allow action buttons to grow with large text.

## Local form fixes

Clear password/token values when changing account forms, entering recovery or returning from recovery/verification. In particular, an old sign-in password must not prefill the new-password field. Clear stage-specific feedback when switching between sign-in and registration, while retaining existing cooldown handling.

## Contract boundaries

No backend, authentication repository, session persistence, validation policy, rate limit, email delivery or token contracts change. The current development repository still uses fixture action tokens; the requested six-digit production flow remains dependent on an agreed backend contract. Verification/reset success still returns to sign-in without authenticating automatically. No real email delivery is claimed. Legacy local data remains isolated.

## Validation

Eight account journey cases cover English/Arabic, light/dark, and normal/2x text at 360 x 800 dp, including a 300 dp keyboard. They exercise keyboard focus order, action reachability, recovery/reset, registration/verification, secret clearing, feedback scope and back navigation. Existing product and accessibility regression suites also apply.
