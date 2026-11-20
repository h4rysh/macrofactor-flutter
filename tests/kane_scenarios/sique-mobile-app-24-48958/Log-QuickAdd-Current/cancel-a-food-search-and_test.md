---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Cancel a food search and return to the log

## Step 1
Cancel a food search and return to the log.

Ensures that a user can start a food search from the persistent bar and cancel the action, returning to the food log without making any changes.

Observe the current state of the food log.
Start a food search from the persistent search bar for 'Broccoli' and cancel the action using the 'Cancel' button or the system back button.
Verify that no new food items have been added to the log.
