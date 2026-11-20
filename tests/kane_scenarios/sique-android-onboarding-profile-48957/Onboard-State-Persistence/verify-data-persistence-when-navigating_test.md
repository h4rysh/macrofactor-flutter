---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Verify data persistence when navigating back and forth in questionnaire

## Step 1
Verify data persistence when navigating back and forth in questionnaire

This test ensures that data entered during the onboarding questionnaire is retained when the user navigates to previous steps and then moves forward again.

Launch the Sique app. Select 'Weight Loss' as the goal and proceed. Select 'Keto' as the diet type. Navigate back. Verify that 'Weight Loss' is still the selected goal. Proceed again. Verify that 'Keto' is still the selected diet type.
