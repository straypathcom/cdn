#!/bin/bash

# Remove macOS extended attributes
echo "Removing macOS extended attributes..."
for file in ./images/*; do
    if [[ -f "$file" && "$file" =~ \.(jpg|jpeg|png)$ ]]; then
        xattr -c "$file" 2>/dev/null
    fi
done

# Remove EXIF metadata using exiftool
echo "Removing EXIF metadata..."
error_log="error_log.txt"  # Log file for errors
> "$error_log"  # Clear the log file before use

# Process each image individually and suppress success messages
for file in ./images/*; do
    if [[ -f "$file" && "$file" =~ \.(jpg|jpeg|png)$ ]]; then
        exiftool -all= -overwrite_original "$file" 1>/dev/null 2>>"$error_log"
    fi
done

# Display summary of errors
if [ -s "$error_log" ]; then
    echo "Some files couldn't be processed. Check $error_log for details."
else
    echo "All files processed successfully with no errors!"
    rm "$error_log"  # Clean up the log file if no errors
fi

echo "Done!"
