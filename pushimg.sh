#!/usr/bin/env bash

# Exit if magick is not installed
command -v magick >/dev/null 2>&1 || {
    echo "Error: ImageMagick (magick) not found. Install it with 'pkg install imagemagick'."
    exit 1
}

# Define the directory paths
LOAD_DIR="gallery/images/load"
FILM_DIR="gallery/images/film_fullsize"
FILM_THUMBS_DIR="gallery/images/film_thumbnails"
LANDSCAPES_DIR="gallery/images/landscapes_fullsize"
LANDSCAPES_THUMBS_DIR="gallery/images/landscapes_thumbnails"
STREET_DIR="gallery/images/street_fullsize"
STREET_THUMBS_DIR="gallery/images/street_thumbnails"
TRAVEL_DIR="gallery/images/travel_fullsize"
TRAVEL_THUMBS_DIR="gallery/images/travel_thumbnails"

FILM_LIST_FILE="$FILM_DIR/filelist.txt"
LANDSCAPES_LIST_FILE="$LANDSCAPES_DIR/filelist.txt"
STREET_LIST_FILE="$STREET_DIR/filelist.txt"
TRAVEL_LIST_FILE="$TRAVEL_DIR/filelist.txt"

# Update file list (only image files)
update_file_list() {
    local dir=$1
    local list_file=$2
    find "$dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -exec basename {} \; > "$list_file"
}

# Update all lists at once
update_all_file_lists() {
    echo "Updating all file lists..."
    update_file_list "$FILM_DIR" "$FILM_LIST_FILE"
    update_file_list "$LANDSCAPES_DIR" "$LANDSCAPES_LIST_FILE"
    update_file_list "$STREET_DIR" "$STREET_LIST_FILE"
    update_file_list "$TRAVEL_DIR" "$TRAVEL_LIST_FILE"
    echo "All file lists updated."
}

# Resize image (with format check)
resize_image() {
    local image_path=$1
    local dest_path=$2
    local max_width=$3
    local max_height=$4

    if [[ ! -f "$image_path" ]]; then
        echo "Error: Image $image_path does not exist. Skipping..."
        return
    fi

    case "$image_path" in
        *.jpg|*.jpeg|*.png)
            magick "$image_path" -resize "${max_width}x${max_height}>" "$dest_path"
            if [[ $? -ne 0 ]]; then
                echo "Error: Failed to resize $image_path"
            else
                echo "Resized $image_path to $dest_path"
            fi
            ;;
        *) echo "Skipping non-image file: $image_path" ;;
    esac
}

# Recreate missing thumbnail
recreate_missing_thumbnail() {
    local thumbnail_file=$1
    local fullsize_file=$2
    [[ "$fullsize_file" == *filelist.txt* ]] && return

    if [[ -f "$fullsize_file" && ! -f "$thumbnail_file" ]]; then
        echo "Recreating thumbnail for $fullsize_file..."
        resize_image "$fullsize_file" "$thumbnail_file" 900 900
    fi
}

# Move resized files to appropriate directories
move_resized_files() {
    for file in "$LOAD_DIR"/*; do
        [[ -f "$file" ]] || continue
        filename=$(basename "$file")
        first_letter=${filename:0:1}
        ext="${filename##*.}"
        name="${filename%.*}"
        category=""
        fullsize_dir=""
        thumb_dir=""
        list_file=""

        case "$first_letter" in
            f|F) category="film"; fullsize_dir="$FILM_DIR"; thumb_dir="$FILM_THUMBS_DIR"; list_file="$FILM_LIST_FILE" ;;
            l|L) category="landscapes"; fullsize_dir="$LANDSCAPES_DIR"; thumb_dir="$LANDSCAPES_THUMBS_DIR"; list_file="$LANDSCAPES_LIST_FILE" ;;
            s|S) category="street"; fullsize_dir="$STREET_DIR"; thumb_dir="$STREET_THUMBS_DIR"; list_file="$STREET_LIST_FILE" ;;
            t|T) category="travel"; fullsize_dir="$TRAVEL_DIR"; thumb_dir="$TRAVEL_THUMBS_DIR"; list_file="$TRAVEL_LIST_FILE" ;;
            *) echo "Skipping unrecognized category: $filename"; continue ;;
        esac

        mkdir -p "$fullsize_dir" "$thumb_dir"

        fullsize_file="$fullsize_dir/$filename"
        thumbnail_file="$thumb_dir/${name}.jpg"

        resize_image "$file" "$fullsize_file" 1850 1850
        resize_image "$file" "$thumbnail_file" 900 900

        echo "Saved resized files to $fullsize_dir and $thumb_dir"
        update_file_list "$fullsize_dir" "$list_file"
    done
}

# Delete orphaned thumbnails
delete_orphaned_thumbnails() {
    echo "Deleting orphaned thumbnails..."
    for thumb_dir in "$FILM_THUMBS_DIR" "$LANDSCAPES_THUMBS_DIR" "$STREET_THUMBS_DIR" "$TRAVEL_THUMBS_DIR"; do
        case "$thumb_dir" in
            "$FILM_THUMBS_DIR") fullsize_dir="$FILM_DIR" ;;
            "$LANDSCAPES_THUMBS_DIR") fullsize_dir="$LANDSCAPES_DIR" ;;
            "$STREET_THUMBS_DIR") fullsize_dir="$STREET_DIR" ;;
            "$TRAVEL_THUMBS_DIR") fullsize_dir="$TRAVEL_DIR" ;;
        esac

        for thumbnail_file in "$thumb_dir"/*; do
            [[ -f "$thumbnail_file" ]] || continue
            filename=$(basename "$thumbnail_file")
            fullsize_file="$fullsize_dir/$filename"
            [[ ! -f "$fullsize_file" ]] && rm "$thumbnail_file" && echo "Deleted $thumbnail_file"
        done
    done
}

# Recreate missing thumbnails
recreate_missing_thumbnails() {
    echo "Recreating missing thumbnails..."
    for thumb_dir in "$FILM_THUMBS_DIR" "$LANDSCAPES_THUMBS_DIR" "$STREET_THUMBS_DIR" "$TRAVEL_THUMBS_DIR"; do
        case "$thumb_dir" in
            "$FILM_THUMBS_DIR") fullsize_dir="$FILM_DIR" ;;
            "$LANDSCAPES_THUMBS_DIR") fullsize_dir="$LANDSCAPES_DIR" ;;
            "$STREET_THUMBS_DIR") fullsize_dir="$STREET_DIR" ;;
            "$TRAVEL_THUMBS_DIR") fullsize_dir="$TRAVEL_DIR" ;;
        esac

        for fullsize_file in "$fullsize_dir"/*; do
            [[ -f "$fullsize_file" ]] || continue
            filename=$(basename "$fullsize_file")
            name="${filename%.*}"
            thumbnail_file="$thumb_dir/${name}.jpg"
            recreate_missing_thumbnail "$thumbnail_file" "$fullsize_file"
        done
    done
}

# Main control

if [[ "$1" == "update_lists" ]]; then
    # Only update file lists and exit
    update_all_file_lists
    exit 0
fi

# Otherwise run the full pipeline:
move_resized_files
delete_orphaned_thumbnails
recreate_missing_thumbnails
