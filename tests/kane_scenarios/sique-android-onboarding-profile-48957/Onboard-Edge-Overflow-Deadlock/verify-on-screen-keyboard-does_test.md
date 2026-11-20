---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Verify on-screen keyboard does not obscure input fields or action buttons

## Step 1
Verify on-screen keyboard does not obscure input fields or action buttons

This test ensures that when a user interacts with an input field during the onboarding questionnaire, the on-screen keyboard does not cover the active field or the primary navigation button.

Launch the Sique mobile app for the first time. Navigate through the onboarding flow to a step requiring text or numeric input, such as the 'Body Metrics' screen. Focus an input field located near the bottom half of the screen. Verify the view adjusts to the keyboard. Enter a valid value into the focused input field and proceed with the primary action button.
