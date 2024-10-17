#!/bin/bash


# ================================================================================
# Include the helper functions
# ================================================================================

if [[ -f "utils.sh" ]]; then
    source utils.sh
else
    echo "File helper_functions.sh not found. Exiting."
    exit 1
fi

# ================================================================================

# ================================================================================
# Variables and Constants declaration
# ================================================================================
timestamp=$(date "+%d-%m-%Y %H:%M:%S")

d4j_csv_projects_file="/framework/projects"
app_file_path="./data"
project_csv_data="$app_file_path/projects_csv_data"
output_dir="$app_file_path/output"
sh_cmd_file_path="$output_dir/sh_files"
checkout_projects_dir="$output_dir/checkout_projects"
logdir="./log"
backup_checked_projects_dir="$output_dir/backup"


# Function to validate and prepare the output directory
validate_inital_directory() {

    log_info "Preparing the output directory: $output_dir" 
    
    validate_or_create_dir "$app_file_path"
    validate_or_create_dir "$output_dir" 
    validate_or_create_dir "$checkout_projects_dir" 
    prepare_directory "$project_csv_data" 
    prepare_directory "$sh_cmd_file_path" 
    validate_or_create_dir "$backup_checked_projects_dir"      
    backup_checked_projects "$checkout_projects_dir" "$backup_checked_projects_dir"
}

# Function to run sh files
run_sh_files() {

    local project_name="$1"
    local sh_file_query
    

    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 <program_name or #>"
        exit 1
    fi

    if [[ $project_name != "#" ]]; then   

        log_info "Running SH commands for project: $project_name"     
        sh_file_query="${project_name}*.sh"        
    else
        log_info "Running SH commands for all projects"
        sh_file_query="*.sh"
    fi
    
    # Loop through all CSV files in the input directory
    for sh_file in "$sh_cmd_file_path"/$sh_file_query; do

        # Check if the file exists and is a file
        if [[ -f "$sh_file" ]]; then
            log_info "Running SH commands for file: $sh_file"  

            # Make the script executable
            chmod +x "$sh_file" 
            ./"$sh_file"           
        else
            log_warn "No .sh files found for $project_name or $sh_cmd_file_path is empty"
        fi
    done

    log_info "File $sh_file processed successfully!"
}


print_init_process_message() {
    echo "======================================================================"
    echo "Starting the checkout process for Defects4J projects"
    echo "======================================================================"
    echo ">>>> DATE: $timestamp"
}


print_end_process_message() {
    echo "======================================================================"
    echo "The checkout process for Defects4J projects is completed!"
    echo "======================================================================"
    echo ">>>> DATE: $timestamp"
}

# ================================================================================
# Main script logic
# Validate and prepare the output directory
# ================================================================================


main(){

    # Setup logging
    setup_logging "$logdir"

    # Check the number of arguments provided
    if [[ $# -ne 3 ]]; then
        log_error "Usage: $0 <d4j_root_dir> <version> <project_name or "#" for all projects>"
        exit 1
    fi

    # Assign the input arguments to variables
    d4j_root_dir="$1"
    version="$2"
    project_name="$3"
    extension=".csv"

    # Check if the Defects4J root directory provided is valid
    if is_directory "$d4j_root_dir"; then
        log_info "Defects4J root directory is valid: $d4j_root_dir"
    else
        log_error "Error: Defects4J root directory is not valid: $d4j_root_dir"
        exit 1
    fi

    # Check if the version provided is valid
    if validate_code_version "$version"; then
        log_info "Version is valid: $version"
    else
        log_error "Error: Invalid version provided: $version"
        exit 1
    fi

    # Start the checkout process
    print_init_process_message

    # Call the function to validate and prepare the output directory
    log_info "Validating and preparing the output directory"
    validate_inital_directory    

    # Get the active project data
    log_info "Moving Active Bug info files from : $d4j_root_dir$d4j_csv_projects_file to $project_csv_data" 
    ./get_projects_files_info.sh "$d4j_root_dir$d4j_csv_projects_file" "$extension" "$project_csv_data" 

    # Generate the project extraction commands
    log_info "Processing active project data"
    ./generate_project_extraction.sh "$project_csv_data" "$sh_cmd_file_path" "$version" "$checkout_projects_dir"

    # Run sh command files to checkout specified project or all projects
    log_info "Running SH commands to checkout projects" 

    if validate_project_name "$project_name"; then

        log_info "Project name is valid: $project_name"
        run_sh_files "$project_name"
        
    else

        log_error "Error: Invalid project name provided: $project_name"
        exit 1
    fi   

    print_end_process_message
}

# ================================================================================
# Main script execution
# ================================================================================


main "$1" "$2" "$3"


