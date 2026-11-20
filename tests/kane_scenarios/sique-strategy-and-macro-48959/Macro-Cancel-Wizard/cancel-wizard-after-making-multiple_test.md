---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Cancel wizard after making multiple changes across different steps

## Step 1
Cancel wizard after making multiple changes across different steps of the setup wizard

Confirms that all modifications across multiple steps of the setup wizard are discarded if the user cancels before completing the flow.

Navigate to the **Strategy** screen and observe the initial values. Open the wizard with the **Edit** button. Adjust the target rate of weight loss and change the macro program from 'Balanced' to 'Low Carb', proceeding to the macro program step. Tap the **Cancel** or **X** button. Verify the calorie target on the **Strategy** screen. Verify the macro program on the **Strategy** screen.
