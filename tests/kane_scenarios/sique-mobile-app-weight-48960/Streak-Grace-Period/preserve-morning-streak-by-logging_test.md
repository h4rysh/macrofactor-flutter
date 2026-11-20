---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Preserve morning streak by logging weight within the grace period

## Step 1
Set the device's system time to 1:30 PM on the current day.
Launch the Sique app and navigate to the main dashboard.
Verify the dashboard displays a "Morning Streak" of "2 days".
Log a valid weight (e.g., "165.5") into the weight input field.
Verify the dashboard's "Morning Streak" indicator has updated to "3 days".
