#!/bin/bash

if [[ -f "utils.sh" ]]; then
    source utils.sh
else
    echo "File helper_functions.sh not found. Exiting."
    exit 1
fi

# Function to search for files with a specific extension in a given directory
search_files_by_extension() {
    # Check if the correct number of arguments is provided
    if [[ $# -ne 2 ]]; then
        echo "Usage: search_files_by_extension <directory> <file_extension>"
        log_error "Invalid number of arguments for search_files_by_extension function."
        return 1
    fi

    # Assign arguments to variables
    local dir="$1"
    local extension="$2"


    # Validate the directory
    if [[ ! -d $dir ]]; then
        echo "Error: '$dir' is not a valid directory."
        log_error "Invalid directory '$dir'."
        return 1
    fi

    # Validate the file extension
    if [[ $extension != .* ]]; then
        echo "Error: File extension must start with a dot (e.g., .txt)."
        log_error "Invalid file extension '$extension'."
        return 1
    fi

    # Use the find command to search for files with the given extension
    local files
    files=$(find "$dir" -type f -name "*$extension" 2>/dev/null)
    
	# Check if any files were found
    if [[ -z $files ]]; then
        echo "null"
    else
        echo "$files"
    fi

    return 0
}

# Example of how to call the function (uncomment to use)
# search_files_by_extension "/path/to/directory" ".txt"


copy_and_rename_file() {
    log_info "Copying and renaming file: $1 to $2"
    # Extract directory and filename from the input path
    file_path="$1"
    target_directory="$2"  # The directory where the file will be copied

    # Extract the directory name (e.g., Compress)
    dir_name=$(basename "$(dirname "$file_path")")

    # Extract the original file name (e.g., deprecated-bugs.csv)
    file_name=$(basename "$file_path")

    # Create the new file name (e.g., Compress_deprecated-bugs.csv)
    new_file_name="${dir_name}_${file_name}"

    # Copy the file to the target directory and rename it
    cp "$file_path" "$target_directory/$new_file_name"
}



# Main script execution
if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <source_directory> <file_extension> <output_directory>"
    log_error "Invalid number of arguments for the script $0"
    exit 1
fi


# Call the function with provided arguments
log_info "Searching for files with extension $2 in directory $1"
list_csv_file=$(search_files_by_extension "$1" "$2")
#csv_dir="./csv_files"

echo "$list_csv_file" | while read line; do
    echo "Processisng file:${line}..."	
    copy_and_rename_file "$line" "$3"
done

