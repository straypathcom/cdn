#!/bin/bash

# Remove macOS extended attributes
echo "Removing macOS extended attributes..."
for file in /images/*.jpg /images/*.jpeg /images/*.png; do
    if [ -f "$file" ]; then
        xattr -c "$file" 2>/dev/null && echo "Cleared attributes for: $file"
    fi
done

# Remove EXIF metadata using exiftool
echo "Removing EXIF metadata..."
exiftool -all= -overwrite_original /images/*.{jpg,jpeg,png} 2>/dev/null && echo "EXIF metadata cleared."

echo "Done!"
