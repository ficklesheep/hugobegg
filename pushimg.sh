#!/bin/bash

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

# Function to update the file list (only for image files)
update_file_list() {
    local dir=$1
    local list_file=$2
    echo "Updating file list in $list_file..."
    
    # Only add image files to the file list, and save only the base filenames (no paths)
    find "$dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -exec basename {} \; > "$list_file"
    echo "File list updated for $dir."
}

# Function to resize images and check if file exists
resize_image() {
    local image_path=$1
    local dest_path=$2
    local max_width=$3
    local max_height=$4

    if [[ ! -f "$image_path" ]]; then
        echo "Error: Image $image_path does not exist. Skipping..."
        return
    fi

    # Ensure only image files are resized (jpg, jpeg, png)
    if [[ "$image_path" =~ \.(jpg|jpeg|png)$ ]]; then
        magick "$image_path" -resize "${max_width}x${max_height}"\> "$dest_path"
        if [[ $? -ne 0 ]]; then
            echo "Error: Failed to resize image $image_path"
        else
            echo "Successfully resized $image_path to $dest_path"
        fi
    else
        echo "Skipping non-image file: $image_path"
    fi
}

# Function to delete orphaned thumbnails (no corresponding full-size image)
delete_orphaned_thumbnail() {
    local thumbnail_file=$1
    local fullsize_file=$2

    if [[ ! -f "$fullsize_file" ]]; then
        echo "Full-size image not found for $thumbnail_file. Deleting orphaned thumbnail."
        rm "$thumbnail_file"
    fi
}

# Function to recreate missing thumbnails
recreate_missing_thumbnail() {
    local thumbnail_file=$1
    local fullsize_file=$2

    # Skip non-image files like filelist.txt
    if [[ "$fullsize_file" == *filelist.txt* ]]; then
        return
    fi

    if [[ -f "$fullsize_file" && ! -f "$thumbnail_file" ]]; then
        echo "Thumbnail for $fullsize_file is missing. Recreating..."
        resize_image "$fullsize_file" "$thumbnail_file" 900 900
        echo "Recreated thumbnail: $thumbnail_file"
    fi
}

# Function to move resized files to appropriate directories
move_resized_files() {
    for file in "$LOAD_DIR"/*; do
        if [[ -f "$file" && "$file" != *filelist.txt && "$file" != *cover.jpg ]]; then
            filename=$(basename "$file")
            category=""

            # Detect image category
            if [[ "$filename" == film_* ]]; then
                category="film"
            elif [[ "$filename" == landscapes_* ]]; then
                category="landscapes"
            elif [[ "$filename" == street_* ]]; then
                category="street"
            elif [[ "$filename" == travel_* ]]; then
                category="travel"
            fi

            # If a category is matched, process the file
            if [[ -n "$category" ]]; then
                # Define fullsize and thumbnail directories based on the category
                case "$category" in
                    "film") fullsize_dir="$FILM_DIR"; thumb_dir="$FILM_THUMBS_DIR" ;;
                    "landscapes") fullsize_dir="$LANDSCAPES_DIR"; thumb_dir="$LANDSCAPES_THUMBS_DIR" ;;
                    "street") fullsize_dir="$STREET_DIR"; thumb_dir="$STREET_THUMBS_DIR" ;;
                    "travel") fullsize_dir="$TRAVEL_DIR"; thumb_dir="$TRAVEL_THUMBS_DIR" ;;
                esac

                # Ensure the directories exist
                mkdir -p "$fullsize_dir" "$thumb_dir"

                # Define full-size and thumbnail file paths
                fullsize_file="$fullsize_dir/$filename"
                thumbnail_file="$thumb_dir/$(basename "$filename" .jpg).jpg"  # Assuming jpg, adjust for other formats

                # Resize and move full-size and thumbnail images
                resize_image "$file" "$fullsize_file" 1850 1850
                resize_image "$file" "$thumbnail_file" 900 900

                # Move resized files into their respective category folders
                mv "$fullsize_file" "$fullsize_dir/"
                mv "$thumbnail_file" "$thumb_dir/"
                echo "Moved resized files to $fullsize_dir and $thumb_dir."

                # Update file lists after processing
                case "$category" in
                    "film") update_file_list "$FILM_DIR" "$FILM_LIST_FILE" ;;
                    "landscapes") update_file_list "$LANDSCAPES_DIR" "$LANDSCAPES_LIST_FILE" ;;
                    "street") update_file_list "$STREET_DIR" "$STREET_LIST_FILE" ;;
                    "travel") update_file_list "$TRAVEL_DIR" "$TRAVEL_LIST_FILE" ;;
                esac
            fi
        fi
    done
}

# Function to delete orphaned thumbnails
delete_orphaned_thumbnails() {
    echo "Checking for orphaned thumbnails..."

    for thumb_dir in "$FILM_THUMBS_DIR" "$LANDSCAPES_THUMBS_DIR" "$STREET_THUMBS_DIR" "$TRAVEL_THUMBS_DIR"; do
        case "$thumb_dir" in
            "$FILM_THUMBS_DIR") fullsize_dir="$FILM_DIR" ;;
            "$LANDSCAPES_THUMBS_DIR") fullsize_dir="$LANDSCAPES_DIR" ;;
            "$STREET_THUMBS_DIR") fullsize_dir="$STREET_DIR" ;;
            "$TRAVEL_THUMBS_DIR") fullsize_dir="$TRAVEL_DIR" ;;
        esac

        for thumbnail_file in "$thumb_dir"/*; do
            if [[ -f "$thumbnail_file" ]]; then
                filename=$(basename "$thumbnail_file")
                fullsize_file="$fullsize_dir/$filename"

                if [[ ! -f "$fullsize_file" ]]; then
                    echo "Full-size image not found for $thumbnail_file. Deleting orphaned thumbnail."
                    rm "$thumbnail_file"
                fi
            fi
        done
    done
}

# Function to recreate missing thumbnails
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
            if [[ -f "$fullsize_file" ]]; then
                filename=$(basename "$fullsize_file")
                thumbnail_file="$thumb_dir/$(basename "$filename" .jpg).jpg"  # Assuming .jpg

                recreate_missing_thumbnail "$thumbnail_file" "$fullsize_file"
            fi
        done
    done
}

# Main script execution
move_resized_files
delete_orphaned_thumbnails
recreate_missing_thumbnails
 