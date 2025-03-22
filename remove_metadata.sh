#!/bin/bash

# Function to process a single file
process_file() {
    local file=$1
    local modified=false

    # Check if file exists
    if [ ! -f "$file" ]; then
        echo "Error: File '$file' not found."
        return 1
    fi

    # Remove macOS extended attributes and check if any were removed
    local attr_before=$(xattr -l "$file" 2>/dev/null | wc -l)
    xattr -c "$file" 2>/dev/null
    local attr_after=$(xattr -l "$file" 2>/dev/null | wc -l)

    if [ "$attr_before" -gt "$attr_after" ]; then
        echo "✓ Cleared extended attributes for: $file"
        modified=true
    fi

    # Check if file has EXIF data before modification
    local before_metadata=$(exiftool -S -all "$file" 2>/dev/null | wc -l)

    # Remove EXIF metadata using exiftool
    result=$(exiftool -all= -overwrite_original "$file" 2>&1)
    status=$?

    if [ $status -ne 0 ]; then
        echo "❌ Error processing file: $file"
        echo "   Error message: $result"
        return 1
    fi

    # Check if file has EXIF data after modification
    local after_metadata=$(exiftool -S -all "$file" 2>/dev/null | wc -l)

    if [ "$before_metadata" -gt "$after_metadata" ]; then
        echo "✓ Removed EXIF metadata from: $file"
        modified=true
    fi

    # Show a summary of metadata for modified files
    if [ "$modified" = true ]; then
        echo "ℹ️ Metadata summary for $file after processing:"
        exiftool -S "$file" | grep -v "^File" | grep -v "^Directory"
        echo "-----------------------------------"
        return 0
    else
        return 2  # Return code 2 indicates no changes were made
    fi
}

# Variables to track changes
total_files=0
modified_files=0
error_files=0

# Check if a specific file was provided
if [ "$#" -eq 1 ]; then
    # Process single file
    process_file "$1"
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "✅ File successfully processed with changes."
    elif [ $exit_code -eq 2 ]; then
        echo "⚠️ File processed, but no changes were necessary."
    fi
else
    # Process all image files
    echo "🔍 Processing all image files..."

    # Process each image file
    for file in ./images/*.jpg ./images/*.jpeg ./images/*.png; do
        if [ -f "$file" ]; then
            ((total_files++))
            process_file "$file"
            exit_code=$?

            if [ $exit_code -eq 0 ]; then
                ((modified_files++))
            elif [ $exit_code -eq 1 ]; then
                ((error_files++))
            fi
        fi
    done

    # Summary
    echo "📊 Summary:"
    echo "  Total files processed: $total_files"
    echo "  Files modified: $modified_files"
    echo "  Files with errors: $error_files"
    echo "  Files unchanged: $((total_files - modified_files - error_files))"
    echo "✅ Done processing all files!"
fi
