---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Resume onboarding at the correct step after backgrounding the app

## Step 1
Resume onboarding at the correct step after backgrounding the app.

Validates that if the user sends the app to the background and reopens it, they are returned to their last step in the questionnaire with all data preserved.

Launch the Sique app, begin the onboarding flow, and complete the questionnaire up to Step 10 (Body Metrics).
On Step 10, enter '75' in the 'Weight' field.
Return to the device's home screen, sending the app to the background.
Reopen the Sique app from the recent apps list or by tapping its icon.
Verify the app resumes at Step 10 (Body Metrics).
Verify the 'Weight' field still contains the value '75'.
