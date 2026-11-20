---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Verify fat macro is clamped for high-calorie weight gain target

## Step 1
Verify fat macro is clamped for high-calorie weight gain target

Tests that for a high-calorie goal (aggressive weight gain), the fat macro is capped at a healthy upper bound, with remaining calories allocated to other macros.

Verify the **Strategy** screen is displayed, showing a calorie target of '2000'.
Edit the strategy in the wizard: change the goal from 'Lose Weight' to 'Gain Weight' and adjust the target rate to a high value (e.g., '+1.5 lbs/week'), which would calculate to a 3500 kcal target. Tap the **Confirm** or **Save** button.
Verify the new high calorie target is displayed.
Verify the fat macro target is clamped at its upper bound.
