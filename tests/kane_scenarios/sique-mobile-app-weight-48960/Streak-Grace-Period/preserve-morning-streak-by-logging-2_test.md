---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Preserve morning streak by logging at the exact end of the grace period

## Step 1
Preserve morning streak by logging at the exact end of the grace period

Edge case test to verify that a weigh-in logged at the last moment of the grace period is accepted and preserves the streak.

Set the device's system time to 1:59 PM on the current day.
Launch the Sique app and navigate to the main dashboard.
Verify the dashboard displays a "Morning Streak" of "2 days".
Log a valid weight (e.g., "165.5") just before the clock changes to 2:00 PM.
Verify the "Morning Streak" indicator has updated to "3 days".
