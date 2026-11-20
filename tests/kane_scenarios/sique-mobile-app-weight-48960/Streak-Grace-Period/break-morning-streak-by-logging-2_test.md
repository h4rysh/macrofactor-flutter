---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Break morning streak by logging immediately after the grace period ends

## Step 1
Break morning streak by logging immediately after the grace period ends

Edge case test to verify that a weigh-in logged immediately after the grace period expires breaks the streak.

Set the device's system time to 2:00 PM on the current day.
Launch the Sique app and navigate to the main dashboard.
Verify the dashboard displays a "Morning Streak" of "2 days".
Log a valid weight (e.g., "165.5").
Verify the "Morning Streak" indicator has reset to "1 day".
