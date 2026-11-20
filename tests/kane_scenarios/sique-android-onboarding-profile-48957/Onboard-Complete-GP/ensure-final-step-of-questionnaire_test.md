---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Ensure final step of questionnaire transitions to dashboard without deadlock

## Step 1
Ensure final step of questionnaire transitions to dashboard without deadlock

This test focuses on the final action of the 24-step questionnaire to ensure that completing the process successfully transitions the user to the dashboard without getting stuck.

Launch the Sique mobile app. Quickly proceed through steps 1-23 of the questionnaire by selecting any valid option for each question. Arrive at the final step (Step 24), which displays the generated macro targets, and tap the **Finish Setup** or **Complete** button.
Wait for up to 10 seconds for the transition to complete.
Verify that the main application dashboard is now visible.
