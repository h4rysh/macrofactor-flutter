---
test: ../verify-on-screen-keyboard-does_test.md
status: failed
started: 2026-11-20T04:04:02.880Z
duration_s: 471
session_id: 099c0d6f-596a-4835-9648-40360715414f
---

# Verify on-screen keyboard does not obscure input fields or action buttons — Result

## Step 1 ✗ failed (443.9s)
md5: 37e07e40c7d735e6c98d238033daee8e
Reason: Focused numeric field shows a cursor but no keyboard after typing and tapping, so the required keyboard checkpoint cannot pass. — bug verdict: Android soft keyboard fails to open for focused weight field [environment_issue/platform_failure, confidence 0.86]
Verify on-screen keyboard does not obscure input fields or action buttons

This test ensures that when a user interacts with an input field during the onboarding questionnaire, the on-screen keyboard does not cover the active field or the primary navigation button.

Launch the Sique mobile app for the first time. Navigate through the onboarding flow to a step requiring text or numeric input, such as the 'Body Metrics' screen. Focus an input field located near the bottom half of the screen. Verify the view adjusts to the keyboard. Enter a valid value into the focused input field and proceed with the primary action button.
