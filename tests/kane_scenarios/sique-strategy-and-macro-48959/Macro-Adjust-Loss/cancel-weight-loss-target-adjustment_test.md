---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Cancel weight loss target adjustment and verify no changes are saved

## Step 1
Cancel weight loss target adjustment and verify no changes are saved.

Ensures that if a user modifies their strategy in the setup wizard but then cancels the operation, the original strategy and targets remain unchanged.

Verify the **Strategy** screen is displayed, showing a calorie target of '2000'.
Edit the strategy and navigate to the 'Rate of Weight Loss' setting.
Adjust the target rate to a different value (e.g., '-1.0 lbs/week'), then cancel the wizard using the **Cancel** button or the system back gesture.
Verify the calorie target has not changed.
Verify the macro targets have not changed.
