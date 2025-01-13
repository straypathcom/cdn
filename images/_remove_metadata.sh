
#!/bin/bash

# Remove macOS extended attributes
echo "Removing macOS extended attributes..."
for file in *.jpg *.jpeg *.png; do
    if [ -f "$file" ]; then
        xattr -c "$file" 2>/dev/null && echo "Cleared attributes for: $file"
    fi
done

# Remove EXIF metadata using exiftool
echo "Removing EXIF metadata..."
exiftool -all= -overwrite_original *.{jpg,jpeg,png} 2>/dev/null && echo "EXIF metadata cleared."

echo "Done!"
