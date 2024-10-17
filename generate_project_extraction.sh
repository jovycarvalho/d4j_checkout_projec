#!/bin/bash

if [[ -f "utils.sh" ]]; then
    source utils.sh
else
    echo "File helper_functions.sh not found. Exiting."
    exit 1
fi


# Function to extract project name from the file name
extract_project_name() {
    local file_name="$1"
    # Extract the project name using the underscore delimiter
    
    local project_name=$(basename "$file_name" | cut -d'_' -f1)
    echo "$project_name"
}


generate_checkout_commands() {
    local csv_file="$1"
    local output_dir="$2"
    local version="$3" # "b" for buggy, "f" for fixed
    local checkout_projects_dir="$4"
    local project_name=$(extract_project_name "$csv_file")    

    local command_count=0

    # Create the output file
    local output_file="${output_dir}/${project_name}_${version}_project_extraction.sh"
    
    # Create a temporary file for storing bug IDs
    local tmp_file=$(mktemp)
    
    # Extract the bug IDs and store them in the temporary file
    awk -F, 'NR>1 {print $1}' "$csv_file" > "$tmp_file"
    
   
    # Process each bug ID in the temporary file
    while read -r bug_id; do
        local vid="${bug_id}${version}"
        local work_dir="$checkout_projects_dir"/"${project_name}-${vid}"       
        echo "defects4j checkout -p $project_name -v $vid -w \"$work_dir\"" >> "$output_file"
        ((command_count++))
    done < "$tmp_file"

    # Remove the temporary file
    rm "$tmp_file"    

    log_info "Processed $csv_file: $command_count commands for $project_name."    
}

# Function to process all CSV files in the directory
process_csv_files() {
    local input_dir="$1"
    local output_dir="$2"
    local version="$3"
    local checkout_projects_dir="$4"
    local file_counter=0
    local csv_file

    # Create buggy and fixed version output directories if they don't exist
    mkdir -p "$output_dir"

    # Check if there are any CSV files in the input directory
    if compgen -G "$input_dir/*_active-bugs.csv" > /dev/null; then
        # Loop through all CSV files in the input directory
        for csv_file in "$input_dir"/*_active-bugs.csv; do
            # Check if csv_file is valid
            if [[ -f "$csv_file" ]]; then
                # Generate commands for buggy versions (version "b")
                if [[ "$version" == "b" ]]; then
                    generate_checkout_commands "$csv_file" "$output_dir" "b" "$checkout_projects_dir"
                fi

                # Generate commands for fixed versions (version "f")
                if [[ "$version" == "f" ]]; then
                    generate_checkout_commands "$csv_file" "$output_dir" "f" "$checkout_projects_dir"
                fi
                ((file_counter++))
            else
                log_warn "File not found: $csv_file"
            fi
        done
        log_info "Processed $file_counter files."
    else
        log_warn "No CSV files found in the directory: $input_dir"
    fi

    # Make the generated scripts executable, if any
    if [[ $file_counter -gt 0 ]]; then
        chmod +x "$output_dir"/*.sh
    else
        log_info "No files were processed, no scripts to make executable."
    fi
}

# Function to validate the input version


# Main script logic
# Usage: ./script.sh /path/to/csv_files /path/to/output_directory

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 <directory> <file_extension> <version>"
    exit 1
fi

input_dir="$1"
output_dir="$2"
version=$3
checkout_projects_dir="$4"


# Check if input directory and output directory are provided
if [ -z "$input_dir" ] || [ -z "$output_dir" ] || [ -z "$checkout_projects_dir" ]; then
    echo "Usage: $0 /path/to/csv_files /path/to/output_command_directory <version> </path/to/checkout_projects>"
    exit 1
fi

# Validate the version input
if ! validate_code_version "$version"; then
    exit 1  # Exit if the input is not valid
fi


# Process the CSV files in the specified directory and check out the projects in the checkout directory
process_csv_files "$input_dir" "$output_dir" "$version" "$checkout_projects_dir"


log_info "Checkout commands generated in $output_dir."
log_info "Checkedout projects in $checkout_projects_dir."