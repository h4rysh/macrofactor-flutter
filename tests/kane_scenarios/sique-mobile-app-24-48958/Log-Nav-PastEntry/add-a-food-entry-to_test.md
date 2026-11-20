---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Add a food entry to a previous empty hour slot

## Step 1
Add a food entry to a previous empty hour slot

Verifies a user can scroll up the 24-hour log, expand a compact empty hour, and successfully add a food item to that past time.

Open the Sique mobile app. Log in with `testuser@sique.app` / `password123`. Scroll up the log to a past, empty time slot, for example, 09:00. Add "Apple" to the 09:00 time slot. Verify the food entry is present.
