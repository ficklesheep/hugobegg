#!/usr/bin/env bash

# Exit if magick is not installed
command -v magick >/dev/null 2>&1 || {
    echo "Error: ImageMagick (magick) not found. Install it with 'pkg install imagemagick'."
    exit 1
}

# Directory paths
FILM_DIR="gallery/images/film_fullsize"
FILM_THUMBS_DIR="gallery/images/film_thumbnails"
LANDSCAPES_DIR="gallery/images/landscapes_fullsize"
LANDSCAPES_THUMBS_DIR="gallery/images/landscapes_thumbnails"
STREET_DIR="gallery/images/street_fullsize"
STREET_THUMBS_DIR="gallery/images/street_thumbnails"
TRAVEL_DIR="gallery/images/travel_fullsize"
TRAVEL_THUMBS_DIR="gallery/images/travel_thumbnails"
COVERS_DIR="gallery/images/carousel"

FILM_LIST_FILE="$FILM_DIR/filelist.txt"
LANDSCAPES_LIST_FILE="$LANDSCAPES_DIR/filelist.txt"
STREET_LIST_FILE="$STREET_DIR/filelist.txt"
TRAVEL_LIST_FILE="$TRAVEL_DIR/filelist.txt"
COVERS_LIST_FILE="$COVERS_DIR/filelist.txt"

# Create missing thumbnail dirs
mkdir -p "$FILM_THUMBS_DIR" "$LANDSCAPES_THUMBS_DIR" "$STREET_THUMBS_DIR" "$TRAVEL_THUMBS_DIR"

# --- Helper: resize/convert image to webp ---
convert_to_webp() {
    local input=$1
    local output=$2
    local width=$3
    local height=$4

    [[ ! -f "$input" ]] && { echo "Missing: $input"; return; }
    [[ -f "$output" ]] && return  # Skip existing

    magick "$input" -resize "${width}x${height}>" -quality 85 "$output"
    echo "✅ Created $output"
}

# --- Helper: update filelist.txt ---
update_file_list() {
    local dir=$1
    local list_file=$2

    # Ignore cover.webp in carousel
    if [[ "$dir" == "$COVERS_DIR" ]]; then
        find "$dir" -maxdepth 1 -type f -iname "*.webp" ! -iname "cover.webp" -exec basename {} \; > "$list_file"
    else
        find "$dir" -maxdepth 1 -type f -iname "*.webp" -exec basename {} \; > "$list_file"
    fi
    echo "📄 Updated $list_file"
}

# --- Process one directory pair ---
process_pair() {
    local full_dir=$1
    local thumb_dir=$2
    local list_file=$3

    echo "Processing $full_dir ..."

    for img in "$full_dir"/*.{jpg,jpeg,png}; do
        [[ -f "$img" ]] || continue
        base=$(basename "$img")
        name="${base%.*}"

        full_webp="$full_dir/$name.webp"
        thumb_webp="$thumb_dir/$name.webp"

        # 1. Convert fullsize to webp (keep original JPG)
        convert_to_webp "$img" "$full_webp" 1850 1850

        # 2. Create thumbnail as webp
        convert_to_webp "$img" "$thumb_webp" 900 900
    done

    # 3. Update filelist
    update_file_list "$full_dir" "$list_file"
}

# --- Main run ---
process_pair "$FILM_DIR" "$FILM_THUMBS_DIR" "$FILM_LIST_FILE"
process_pair "$LANDSCAPES_DIR" "$LANDSCAPES_THUMBS_DIR" "$LANDSCAPES_LIST_FILE"
process_pair "$STREET_DIR" "$STREET_THUMBS_DIR" "$STREET_LIST_FILE"
process_pair "$TRAVEL_DIR" "$TRAVEL_THUMBS_DIR" "$TRAVEL_LIST_FILE"

# Process carousel (no thumbnails)
for img in "$COVERS_DIR"/*.{jpg,jpeg,png}; do
    [[ -f "$img" ]] || continue
    name="${img%.*}"
    convert_to_webp "$img" "$name.webp" 1850 1850
done
update_file_list "$COVERS_DIR" "$COVERS_LIST_FILE"

echo "✅ All conversions complete."
