---
mode: testing
max_steps: 30
timeout: 300
variables: {}
---

# Export a large data set to test Android binder transaction limits

## Step 1
Export a large data set to test Android binder transaction limits

Verifies the app remains stable and handles the export of a very large data set gracefully, avoiding crashes related to Android's binder transaction limits.

Export the large data set from the **More** tab via the **Settings** option, the **Export Data** option, and the **Share as File** option.
Wait for the native share sheet to appear.
Save the file using a file-saving application like 'Save to Drive' or 'Save to device'.
Get the saved file and save as {{saved_file}}.
Open {{saved_file}} and verify its integrity.
