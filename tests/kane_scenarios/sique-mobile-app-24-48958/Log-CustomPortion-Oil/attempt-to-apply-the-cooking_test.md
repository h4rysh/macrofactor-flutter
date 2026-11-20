---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Attempt to apply the cooking oil modifier twice and verify it is only counted once

## Step 1
Attempt to apply the cooking oil modifier twice and verify it is only counted once.

Checks that the system prevents double-counting by either disabling the modifier button after one application or ignoring subsequent applications.

From the main log screen, search for 'Chicken Breast' and select it from the results.
Select '1 slice' as the portion unit.
Apply the 'Add Cooking Oil' modifier.
Verify the 'Add Cooking Oil' button is now in a selected or 'remove' state.
Apply the active 'Add Cooking Oil' modifier again.
Verify the total macros do not increase and still reflect only a single application of oil.
