#!/bin/bash

setup_logging() {
    local log_dir="$1"
    local timestamp=$(date "+%Y%m%d%H%M%S")
    local log_file="${log_dir}/checkout_projects_log_${timestamp}.log"

    mkdir -p "$log_dir"
    exec > >(tee -i "$log_file") 2>&1

    echo "======================================================================"
    echo "Logging initialized. Output will be written to: $log_file"
    echo "======================================================================"
}


# Function to write logs
log_message() {
    local log_level="$1"
    local log_message="$2"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$timestamp [$log_level] $log_message" 
}


# Function to log INFO level messages
log_info() {
    log_message "INFO" "$1"
}


# Function to log ERROR level messages
log_error() {
    log_message "ERROR" "$1"
}


# Function to log WARN level messages
log_warn() {
    log_message "WARN" "$1"
}


# Function to log DEBUG level messages (optional, could be enabled only in dev)
log_debug() {
    # Uncomment the next line to enable debug logging
    # log_message "DEBUG" "$1"
    :
}


# Function to check if the directory path is provided
validate_input() {
    local dir_path="$1"
    if [[ -z "$dir_path" ]]; then
        log_error "No directory path provided."
        return 1
    fi
    return 0
}


# Function: Check if a path exists
path_exists() {
    local path="$1"
    
    if [[ -e "$path" ]]; then
        return 0  # Path exists
    else
        return 1  # Path does not exist
    fi
}


# Function: Check if the path is a file
is_file() {
    local path="$1"
    
    if [[ -f "$path" ]]; then
        return 0  # Path is a file
    else
        return 1  # Path is not a file
    fi
}


# Function: Create a file
create_file() {
    local file_path="$1"
    
    touch "$file_path" && log_info "File created: $file_path" || log_error "Failed to create file: $file_path."
}


# Function: Validate or create the file
validate_or_create_file() {
    local file_path="$1"

    # Validate input
    if [[ -z "$file_path" ]]; then
        log_error "No file path provided. Please specify a valid file path."
        return 1  # Exit with error
    fi

    # Check if the path exists
    if path_exists "$file_path"; then
        if is_file "$file_path"; then
            log_info "File exists: $file_path. No action needed."
        else
            log_error "Path exists but is not a file: $file_path."
            return 1  # Exit with error
        fi
    else
        # Path does not exist, create the file
        create_file "$file_path"
    fi
}

# Function: Check if the path is a directory, create if it does not exist
validate_or_create_dir() {
    local dir_path="$1"

    # Validate input
    if [[ -z "$dir_path" ]]; then
        log_error "No file path provided. Please specify a valid file path."
        return 1  # Exit with error
    fi

    # Check if the path exists
    if path_exists "$dir_path"; then
        if is_directory "$dir_path"; then
            log_info "Directory exists: $dir_path. No action needed."
        else
            log_error "Path exists but is not a directory: $dir_path."
            return 1  # Exit with error
        fi
    else
        # Path does not exist, create the directory
        create_directory "$dir_path"
    fi
}

# Function to check if a path exists and is a directory
is_directory() {
    local dir_path="$1"
    if [[ -d "$dir_path" ]]; then
        return 0  # true
    else
        return 1  # false
    fi
}


# Function to clean the directory
clean_directory() {
    local dir_path="$1"
    log_info "Cleaning directory: $dir_path"
    rm -rf "$dir_path"/*
}


# Function to create the directory
create_directory() {
    local dir_path="$1"
    log_info "Creating directory: $dir_path"
    mkdir -p "$dir_path"
}


# Main function to validate and prepare the directory
prepare_directory() {
    local dir_path="$1"

    log_info "Starting to prepare directory: $dir_path"
    # Validate input
    validate_input "$dir_path" || return 1

    # Check if the path exists and is a directory
    if is_directory "$dir_path"; then
        # Clean the directory
        clean_directory "$dir_path"
    else
        # Create the directory
        create_directory "$dir_path"
    fi

    # Confirm the operation
    log_info "Directory is ready: $dir_path"
}


validate_code_version() {
    local input="$1"
    case "$input" in
        b|f)
            return 0  # Valid input
            ;;
        *)
            echo "Error: Invalid input '$input'. Please use 'b' for buggy or 'f' for fixed."
            return 1  # Invalid input
            ;;
    esac
}


# Function to validate if input is text or '#'
validate_project_name() {
    local input="$1"

    # Check if the input is alphabetic (text)
    if [[ "$input" =~ ^[a-zA-Z]+$ ]]; then
        echo "Input is text: $input"

    # Check if the input is the character '#'
    elif [[ "$input" == "#" ]]; then
        echo "Input is the special character '#': $input"
    else
        echo "Invalid input: $input"
        return 1
    fi
}


# Function to backup checked projects to a backup directory
backup_checked_projects() {
    local checkout_projects_dir="$1"
    local backup_base_dir="$2"
    local timestamp=$(date "+%Y%m%d%H%M%S")
    
    # Ensure the checkout projects directory exists
    if ! is_directory "$checkout_projects_dir"; then
        log_error "Error: Checkout projects directory does not exist: $checkout_projects_dir"
        exit 1
    fi
    
    # Ensure the backup base directory exists
    if ! is_directory "$backup_base_dir"; then
        log_error "Error: Backup base directory does not exist: $backup_base_dir"
        exit 1
    fi

    # Create the backup directory inside the base directory
    local backup_dir="$backup_base_dir/backup_$timestamp"
    validate_or_create_dir "$backup_dir"
    
    log_info "Backing up checked projects to: $backup_dir"
    
    # Proceed to move contents if the directory was created or exists
    if is_directory "$backup_dir"; then
        if ! is_directory_empty "$checkout_projects_dir"; then
           log_info "Moving contents from: $checkout_projects_dir to $backup_dir"
            mv "$checkout_projects_dir"/* "$backup_dir" 2>/dev/null
        else           
            log_info "No projects to backup. Directory is empty: $checkout_projects_dir"
        fi
        
        # Check if move operation succeeded
        if [[ $? -eq 0 ]]; then
            log_info "Backup successful to: $backup_dir"
        else
            log_error "Error: Failed to move contents from $checkout_projects_dir to $backup_dir"
            exit 1
        fi
    else
        log_error "Error: Failed to create or access the backup directory: $backup_dir"
        exit 1
    fi
}

is_directory_empty() {
    local dir_path="$1"
    # Use find to check if the directory is empty
    if [ -z "$(find "$dir_path" -mindepth 1 -print -quit)" ]; then
        return 0  # Directory is empty
    else
        return 1  # Directory is not empty
    fi
}