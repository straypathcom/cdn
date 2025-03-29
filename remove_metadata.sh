#!/bin/bash
# filepath: /Users/peterbenoit/GitHub/straypathcom/cdn/remove_metadata.sh

# Function to check if a file was recently modified
is_recently_modified() {
    local file=$1
    local days=$2  # Number of days to consider "recent"

    # Get file's modification time in seconds since epoch
    local file_mtime=$(stat -f %m "$file")
    # Get current time in seconds since epoch
    local current_time=$(date +%s)
    # Calculate threshold in seconds
    local threshold_seconds=$((days * 24 * 60 * 60))
    # Calculate file age
    local file_age=$((current_time - file_mtime))

    # Return true if file is newer than threshold
    [ $file_age -lt $threshold_seconds ]
}

# Function to process a single file
process_file() {
    local file=$1
    local modified=false
    local max_width=1800

    # Check if file exists
    if [ ! -f "$file" ]; then
        echo "Error: File '$file' not found."
        return 1
    fi

    # Check if ImageMagick is installed and determine correct command
    if command -v magick &> /dev/null; then
        # For ImageMagick 7+
        local convert_cmd="magick"
        local identify_cmd="magick identify"
    elif command -v convert &> /dev/null; then
        # For ImageMagick 6 and below
        local convert_cmd="convert"
        local identify_cmd="identify"
    else
        echo "❌ ImageMagick is not installed. Please install it using:"
        echo "   brew install imagemagick"
        return 1
    fi

    # Get original image dimensions
    local dimensions=$(${identify_cmd} -format "%wx%h" "$file" 2>/dev/null)
    local original_width=$(echo $dimensions | cut -d'x' -f1)

    # Check if image needs resizing (width > max_width)
    if [ "$original_width" -gt "$max_width" ]; then
        echo "🔄 Resizing image: $file"
        echo "   Original dimensions: $dimensions"

        # Create temporary file for resizing
        local temp_file="${file}.temp"

        # Resize image maintaining aspect ratio
        ${convert_cmd} "$file" -resize ${max_width}x -quality 95 "$temp_file"

        if [ $? -eq 0 ]; then
            # Get new dimensions
            local new_dimensions=$(${identify_cmd} -format "%wx%h" "$temp_file" 2>/dev/null)

            # Replace original with resized version
            mv "$temp_file" "$file"
            echo "✅ Resized to: $new_dimensions"
            modified=true
        else
            echo "❌ Failed to resize image: $file"
            [ -f "$temp_file" ] && rm "$temp_file"
        fi
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

# Default settings
process_all=false
days_threshold=1  # Default: process files modified in the last day

# Parse command line options
while getopts "ad:h" opt; do
  case $opt in
    a)
      process_all=true
      ;;
    d)
      days_threshold=$OPTARG
      ;;
    h)
      echo "Usage: $0 [-a] [-d days] [file]"
      echo "  -a: Process all image files (not just recently modified)"
      echo "  -d days: Process files modified in the last N days (default: 1)"
      echo "  file: Process a specific file"
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

# Variables to track changes
total_files=0
modified_files=0
error_files=0
skipped_files=0

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
    # Process image files
    if [ "$process_all" = true ]; then
        echo "🔍 Processing ALL image files..."
    else
        echo "🔍 Processing images modified in the last $days_threshold day(s)..."
    fi

    # Process each image file
    for file in ./images/*.jpg ./images/*.jpeg ./images/*.png; do
        if [ -f "$file" ]; then
            ((total_files++))

            # Skip files that aren't recent unless process_all is true
            if [ "$process_all" = false ] && ! is_recently_modified "$file" "$days_threshold"; then
                # echo "⏩ Skipping older file: $file"
                ((skipped_files++))
                continue
            fi

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
    echo "  Total files found: $total_files"
    echo "  Files processed: $((total_files - skipped_files))"
    echo "  Files modified: $modified_files"
    echo "  Files with errors: $error_files"
    echo "  Files unchanged: $((total_files - skipped_files - modified_files - error_files))"
    echo "  Files skipped (not recent): $skipped_files"
    echo "✅ Done!"
fi
