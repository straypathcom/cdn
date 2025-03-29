# CDN - Content Delivery Network

Image storage and processing system using GitHub Pages as a CDN for the Straypath website.

## Overview

This repository functions as a content delivery network (CDN) for images. It includes:

1. **Image storage** in the `/images` directory
2. **Local image processing** with `remove_metadata.sh` for optimization
3. **Automated image processing** via GitHub Actions workflow
4. **CDN delivery** through GitHub Pages

## Usage

### Adding Images

1. Add your images to the `/images` directory
2. Run the image optimization script
3. Commit and push to GitHub
4. The GitHub workflow will automatically create and deploy multiple resolutions

### Accessing Images

Images can be accessed at:

```
https://straypathcom.github.io/cdn/[size]/[filename]
```

Available sizes:

-   `thumbnail` (188x96px)
-   `small` (292x256px)
-   `medium` (395x192px)
-   `hero` (1720x677px)
-   `square` (500x500px, center-cropped)

Example:

```
https://straypathcom.github.io/cdn/medium/example.jpg
```

## Image Processing

### Local Processing (remove_metadata.sh)

The `remove_metadata.sh` script optimizes images before committing:

#### Features

-   Removes EXIF metadata
-   Removes macOS extended attributes
-   Resizes images to maximum width of 1800px while preserving aspect ratio
-   Maintains image quality (95%)
-   Reports which files were modified
-   By default, only processes recently modified files to save time

#### Requirements

-   macOS or Linux with Bash
-   ImageMagick (`brew install imagemagick`)
-   ExifTool (`brew install exiftool`)

#### Usage

```bash
# Process images modified in the last day (default behavior)
./remove_metadata.sh

# Process all images regardless of modification time
./remove_metadata.sh -a

# Process images modified in the last N days (e.g., 7 days)
./remove_metadata.sh -d 7

# Display help information
./remove_metadata.sh -h

# Process a single image
./remove_metadata.sh ./images/example.jpg
```

### Automated Processing (GitHub Actions)

The `.github/workflows/resize.yml` workflow:

1. Triggers on push to the main branch
2. Creates multiple resolution versions of each image
3. Deploys them to the `gh-pages` branch
4. Makes them accessible via GitHub Pages

## License

All rights reserved.
