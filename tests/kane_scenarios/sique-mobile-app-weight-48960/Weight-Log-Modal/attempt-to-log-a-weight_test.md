---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Attempt to log a weight of zero or a negative number

## Step 1
Attempt to log a weight of zero or a negative number.

The system should reject weight entries that are zero or negative, as these are physically impossible, and provide clear feedback.

From the main dashboard, log a weight of '0'. Then log a weight of '-50'.
