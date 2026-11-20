---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Reject out-of-range low values for body metrics

## Step 1
Reject out-of-range low values for body metrics

Ensures that entering zero, negative, or logically implausible low values for height, weight, and age triggers validation errors.

Launch the Sique mobile app for the first time and navigate through the onboarding steps to the body metrics screen.
Enter '0' into the **Height** input field.
Clear the **Height** field and enter a valid height.
Enter '-5' into the **Weight** input field.
Clear the **Weight** field and enter a valid weight.
Enter '12' into the **Age** input field.
Verify the **Continue** button is disabled.
