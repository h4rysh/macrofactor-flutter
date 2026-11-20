---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Attempt to log a non-numeric weight value

## Step 1
Attempt to log a non-numeric weight value

The system should prevent the user from logging a non-numeric value as a weight and display an appropriate error message.

From the main dashboard, log a non-numeric value, such as 'abc', into the **Weight** input field and save.
Verify the modal remains open.
