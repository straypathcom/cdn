#!/bin/bash

# Function to process a single file
process_file() {
    local file=$1

    # Check if file exists
    if [ ! -f "$file" ]; then
        echo "Error: File '$file' not found."
        return 1
    fi

    # Remove macOS extended attributes
    echo "Removing macOS extended attributes for: $file"
    xattr -c "$file" 2>/dev/null && echo "Cleared attributes for: $file"

    # Remove EXIF metadata using exiftool
    echo "Removing EXIF metadata for: $file"
    exiftool -all= -overwrite_original "$file" 2>&1

    if [ $? -eq 0 ]; then
        echo "Successfully processed: $file"
    else
        echo "Error processing: $file"
    fi
}

# Check if a specific file was provided
if [ "$#" -eq 1 ]; then
    # Process single file
    process_file "$1"
else
    # Process all image files
    echo "Processing all image files..."

    # Remove macOS extended attributes
    echo "Removing macOS extended attributes..."
    for file in ./images/*.jpg ./images/*.jpeg ./images/*.png; do
        if [ -f "$file" ]; then
            xattr -c "$file" 2>/dev/null && echo "Cleared attributes for: $file"
        fi
    done

    # Remove EXIF metadata using exiftool with detailed error reporting
    echo "Removing EXIF metadata..."
    for file in ./images/*.jpg ./images/*.jpeg ./images/*.png; do
        if [ -f "$file" ]; then
            result=$(exiftool -all= -overwrite_original "$file" 2>&1)
            status=$?
            if [ $status -ne 0 ]; then
                echo "Error processing file: $file"
                echo "Error message: $result"
            fi
        fi
    done

    echo "Done processing all files!"
fi
