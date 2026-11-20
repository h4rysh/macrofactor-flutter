---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Verify search debounce mechanism and query suggestions

## Step 1
Verify search debounce mechanism and query suggestions

This test ensures that as a user types a search query, the system waits for a brief pause (debounce) before displaying relevant query suggestions.

Search for "chick" using the persistent search bar at the bottom of the screen.
Pause typing for approximately 300-500 milliseconds.
Complete the query "chicken breast".
Pause typing again.
