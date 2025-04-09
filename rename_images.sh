#!/bin/bash
# filepath: /Users/peterbenoit/GitHub/straypathcom/cdn/rename_files.sh

# Variables to track changes
total_files=0
renamed_files=0

echo "🔍 Looking for image files with hyphens in /images..."

# Process each image file
for file in ./images/*.jpg ./images/*.jpeg ./images/*.png; do
    if [ -f "$file" ]; then
        ((total_files++))

        # Get filename and check if it contains hyphens
        filename=$(basename "$file")
        new_filename="${filename//-/_}"

        # Only process files that actually have hyphens
        if [ "$filename" != "$new_filename" ]; then
            new_path="./images/$new_filename"
            echo "🔄 Renaming: $filename → $new_filename"

            # Rename the file
            mv "$file" "$new_path"
            ((renamed_files++))
        fi
    fi
done

# Summary
echo "📊 Summary:"
echo "  Total files found: $total_files"
echo "  Files renamed: $renamed_files"
echo "✅ Done!"
