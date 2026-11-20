---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Ensure subsequent step data is preserved when a previous step is modified

## Step 1
Ensure subsequent step data is preserved when a previous step is modified.

Verifies that changing an answer on a previous step during back-navigation does not clear out the data entered on subsequent, unrelated steps.

Launch the Sique app to start onboarding. Select 'Weight Loss' as the goal. Select 'Balanced' as the diet type. Tap the 'Back' button twice to return to Step 1. Change the goal selection to 'Weight Gain'. Tap the 'Next' button to proceed to Step 2. Verify that the 'Balanced' diet type is still selected.
