---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Restore onboarding state correctly after the app is force-closed

## Step 1
Restore onboarding state correctly after the app is force-closed

Tests that user progress and data are saved and restored correctly even when the app is terminated unexpectedly (force-closed) during the onboarding process.

Launch the Sique app and start the onboarding flow. Progress through the questionnaire to Step 15 (Workout Schedule). Select '3 days a week' for the workout schedule.
Force-close the Sique app via the Android OS settings or recent apps menu.
Relaunch the Sique app from the app drawer.
Verify that the app opens directly to Step 15 (Workout Schedule).
Verify that '3 days a week' is still selected.
