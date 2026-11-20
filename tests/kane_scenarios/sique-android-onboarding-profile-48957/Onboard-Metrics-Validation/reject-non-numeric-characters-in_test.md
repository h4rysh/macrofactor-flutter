---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Reject non-numeric characters in body metrics fields

## Step 1
Reject non-numeric characters in body metrics fields

Verifies that entering non-numeric text into the height, weight, and age fields during onboarding displays an appropriate error message and blocks progression.

Launch the Sique mobile app for the first time. Navigate through the onboarding steps until the body metrics screen is reached. Fill the body metrics fields:
Height: abc
Weight: xyz
Age: test
Attempt to continue.
