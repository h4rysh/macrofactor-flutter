---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Break morning streak by logging weight after the grace period

## Step 1
Break morning streak by logging weight after the grace period

Verifies that logging a weight after the grace period has expired correctly breaks the user's active morning weigh-in streak.

Set the device's system time to 2:30 PM on the current day.
Launch the Sique app and navigate to the main dashboard.
Verify the dashboard displays a "Morning Streak" of "2 days".
Log a valid weight (e.g., "165.5") into the weight input field.
Verify the "Morning Streak" indicator has reset to "1 day".
