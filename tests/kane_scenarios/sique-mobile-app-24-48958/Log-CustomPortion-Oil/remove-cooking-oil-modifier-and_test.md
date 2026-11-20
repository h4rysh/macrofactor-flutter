---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Remove cooking oil modifier and verify macro totals revert to base values

## Step 1
Remove cooking oil modifier and verify macro totals revert to base values.

Ensures that removing an applied cooking oil modifier correctly subtracts its macronutrient values, reverting the total to the base food's macros before logging.

From the main log screen, search for 'Chicken Breast' and select it from the results.
Select '1 slice' as the portion unit.
Add the 'Add Cooking Oil' modifier and deactivate it.
Verify the total macros revert to the base values for the slice.
Log Food.
