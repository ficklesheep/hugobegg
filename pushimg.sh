#!/usr/bin/env bash

# Exit if magick is not installed
command -v magick >/dev/null 2>&1 || {
    echo "Error: ImageMagick (magick) not found. Install it with 'pkg install imagemagick'."
    exit 1
}

# Directory paths
LOAD_DIR="gallery/images/load"
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

# Update file list (only image files, remove missing)
update_file_list() {
    local dir=$1
    local list_file=$2

    # For carousel, ignore cover.jpg
    if [[ "$dir" == "$COVERS_DIR" ]]; then
        find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
            ! -iname "cover.jpg" -exec basename {} \; > "$list_file"
    else
        find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
            -exec basename {} \; > "$list_file"
    fi
}

# Update all file lists
update_all_file_lists() {
    echo "Updating all file lists..."
    update_file_list "$FILM_DIR" "$FILM_LIST_FILE"
    update_file_list "$LANDSCAPES_DIR" "$LANDSCAPES_LIST_FILE"
    update_file_list "$STREET_DIR" "$STREET_LIST_FILE"
    update_file_list "$TRAVEL_DIR" "$TRAVEL_LIST_FILE"
    update_file_list "$COVERS_DIR" "$COVERS_LIST_FILE"
    echo "All file lists updated."
}

# Resize image
resize_image() {
    local image_path=$1
    local dest_path=$2
    local max_width=$3
    local max_height=$4

    [[ ! -f "$image_path" ]] && { echo "Skipping missing $image_path"; return; }
    magick "$image_path" -resize "${max_width}x${max_height}>" "$dest_path"
    echo "Resized $image_path -> $dest_path"
}

# Recreate missing thumbnail
recreate_missing_thumbnail() {
    local thumb_file=$1
    local full_file=$2
    [[ ! -f "$full_file" || -f "$thumb_file" ]] && return
    resize_image "$full_file" "$thumb_file" 900 900
}

# Move files from LOAD_DIR
move_resized_files() {
    for file in "$LOAD_DIR"/*; do
        [[ -f "$file" ]] || continue
        filename=$(basename "$file")
        first_letter=${filename:0:1}

        # Skip carousel cover.jpg
        [[ "$first_letter" == [cC] && "$filename" == "cover.jpg" ]] && { echo "Skipping $filename"; continue; }

        name="${filename%.*}"
        ext="${filename##*.}"

        case "$first_letter" in
            f|F) full="$FILM_DIR"; thumb="$FILM_THUMBS_DIR"; list="$FILM_LIST_FILE" ;;
            l|L) full="$LANDSCAPES_DIR"; thumb="$LANDSCAPES_THUMBS_DIR"; list="$LANDSCAPES_LIST_FILE" ;;
            s|S) full="$STREET_DIR"; thumb="$STREET_THUMBS_DIR"; list="$STREET_LIST_FILE" ;;
            t|T) full="$TRAVEL_DIR"; thumb="$TRAVEL_THUMBS_DIR"; list="$TRAVEL_LIST_FILE" ;;
            c|C) full="$COVERS_DIR"; thumb=""; list="$COVERS_LIST_FILE" ;;
            *) echo "Skipping unknown category: $filename"; continue ;;
        esac

        mkdir -p "$full"
        [[ -n "$thumb" ]] && mkdir -p "$thumb"

        resize_image "$file" "$full/$filename" 1850 1850
        [[ -n "$thumb" ]] && resize_image "$file" "$thumb/$name.jpg" 900 900

        update_file_list "$full" "$list"
    done
}

# Delete orphaned thumbnails
delete_orphaned_thumbnails() {
    for thumb_dir in "$FILM_THUMBS_DIR" "$LANDSCAPES_THUMBS_DIR" "$STREET_THUMBS_DIR" "$TRAVEL_THUMBS_DIR"; do
        [[ -d "$thumb_dir" ]] || continue
        full_dir=""
        case "$thumb_dir" in
            "$FILM_THUMBS_DIR") full_dir="$FILM_DIR" ;;
            "$LANDSCAPES_THUMBS_DIR") full_dir="$LANDSCAPES_DIR" ;;
            "$STREET_THUMBS_DIR") full_dir="$STREET_DIR" ;;
            "$TRAVEL_THUMBS_DIR") full_dir="$TRAVEL_DIR" ;;
        esac
        for thumb in "$thumb_dir"/*; do
            [[ -f "$thumb" ]] || continue
            [[ ! -f "$full_dir/$(basename "$thumb")" ]] && { rm "$thumb"; echo "Deleted orphan $thumb"; }
        done
    done
}

# Recreate missing thumbnails
recreate_missing_thumbnails() {
    for thumb_dir in "$FILM_THUMBS_DIR" "$LANDSCAPES_THUMBS_DIR" "$STREET_THUMBS_DIR" "$TRAVEL_THUMBS_DIR"; do
        full_dir=""
        case "$thumb_dir" in
            "$FILM_THUMBS_DIR") full_dir="$FILM_DIR" ;;
            "$LANDSCAPES_THUMBS_DIR") full_dir="$LANDSCAPES_DIR" ;;
            "$STREET_THUMBS_DIR") full_dir="$STREET_DIR" ;;
            "$TRAVEL_THUMBS_DIR") full_dir="$TRAVEL_DIR" ;;
        esac
        for full_file in "$full_dir"/*; do
            [[ -f "$full_file" ]] || continue
            name="${full_file##*/}"; name="${name%.*}"
            recreate_missing_thumbnail "$thumb_dir/$name.jpg" "$full_file"
        done
    done
}

# Main
if [[ "$1" == "update_lists" ]]; then
    update_all_file_lists
    exit 0
fi

move_resized_files
delete_orphaned_thumbnails
recreate_missing_thumbnails
update_all_file_lists  # <-- ensures file lists reflect current state
