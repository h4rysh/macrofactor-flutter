---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Verify calorie target respects safety floor with aggressive weight loss goal

## Step 1
Verify calorie target respects safety floor with aggressive weight loss goal

Tests that setting a maximum weight loss rate correctly caps the daily calorie target at the predefined safety minimum, preventing unsafe recommendations.

Verify the **Strategy** screen is displayed, showing a calorie target of '2000'.
Set the 'Rate of Weight Loss' setting to the maximum possible value (e.g., '-2.0 lbs/week') and tap the **Confirm** or **Save** button.
Verify the calorie target is capped at the safety floor.
Verify a warning message is displayed about the adjustment.
