#!/bin/bash

# Loop through all JPG/JPEG files in the current directory
for img in *.jpg *.jpeg *.JPG *.JPEG; do
  # Skip if no files found
  [ -e "$img" ] || continue

  # Get filename without extension
  name="${img%.*}"

  # Convert to WebP, resize to max 1920px (maintain aspect ratio), quality 80
  magick "$img" -resize 1920x1920\> -quality 80 "$name.webp"

  # If conversion successful, delete original
  if [ -f "$name.webp" ]; then
    rm "$img"
    echo "Converted and removed: $img -> $name.webp"
  else
    echo "Failed to convert: $img"
  fi
done

echo "All images processed!"
