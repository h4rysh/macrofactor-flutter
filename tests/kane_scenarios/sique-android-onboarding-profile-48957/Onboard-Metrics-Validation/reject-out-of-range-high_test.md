---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Reject out-of-range high values for body metrics

## Step 1
Reject out-of-range high values for body metrics

Ensures that entering excessively high, humanly impossible values for height, weight, and age triggers validation errors.

Launch the Sique mobile app for the first time.
Navigate through the onboarding steps to the body metrics screen.
Enter:
Height: '999'
Weight: '2000'
Age: '150'
Verify the **Continue** button is disabled or cannot be tapped.
