#!/usr/bin/env fish

# PostgreSQL Force Restore Script
# Usage: script.fish <backup-file> <username>:<password>@<host>:<port>/<db-name> [log-dir]

# Parse arguments
if test (count $argv) -lt 2
    echo "Error: Missing required arguments"
    set script_name (basename (status filename))
    echo "Usage: $script_name <backup-file> <username>:<password>@<host>:<port>/<db-name> [log-dir]"
    exit 1
end

set backup_file $argv[1]
set connection_string $argv[2]
set log_dir "./logs"

# Parse optional log directory argument
if test (count $argv) -ge 3
    set log_dir $argv[3]
end

# Setup logging
set timestamp (date +"%Y-%m-%d_%H-%M-%S")
set log_file "$log_dir/restore_$timestamp.log"

# Create log directory if it doesn't exist
mkdir -p $log_dir
if test $status -ne 0
    echo "Error: Failed to create log directory: $log_dir"
    exit 1
end

# Log function
function log_message
    set -l message $argv[1]
    echo $message | tee -a $log_file
end

# Log start
log_message "=== PostgreSQL Force Restore Script ==="
log_message "Started at: "(date)
log_message "Backup file: $backup_file"
log_message "Connection string: $connection_string"
log_message "Log directory: $log_dir"
log_message ""

# Parse connection string: username:password@host:port/db-name
set conn_parts (string split "@" $connection_string)
if test (count $conn_parts) -ne 2
    log_message "Error: Invalid connection string format. Expected: username:password@host:port/db-name"
    exit 1
end

set user_pass $conn_parts[1]
set host_port_db $conn_parts[2]

# Extract username and password
set user_pass_parts (string split ":" $user_pass)
if test (count $user_pass_parts) -ne 2
    log_message "Error: Invalid username:password format in connection string"
    exit 1
end
set db_user $user_pass_parts[1]
set db_password $user_pass_parts[2]

# Extract host, port, and database name
set host_port_db_parts (string split "/" $host_port_db)
if test (count $host_port_db_parts) -ne 2
    log_message "Error: Invalid host:port/db-name format in connection string"
    exit 1
end

set host_port $host_port_db_parts[1]
set db_name $host_port_db_parts[2]

# Extract host and port
set host_port_parts (string split ":" $host_port)
if test (count $host_port_parts) -eq 1
    set db_host $host_port_parts[1]
    set db_port "5432"
else if test (count $host_port_parts) -eq 2
    set db_host $host_port_parts[1]
    set db_port $host_port_parts[2]
else
    log_message "Error: Invalid host:port format in connection string"
    exit 1
end

log_message "Parsed connection details:"
log_message "  Username: $db_user"
log_message "  Host: $db_host"
log_message "  Port: $db_port"
log_message "  Database: $db_name"
log_message ""

# Validate backup file exists
if not test -f $backup_file
    log_message "Error: Backup file does not exist: $backup_file"
    exit 1
end

if not test -r $backup_file
    log_message "Error: Backup file is not readable: $backup_file"
    exit 1
end

log_message "Backup file validated: $backup_file"
log_message ""

# Set password for PostgreSQL commands
set -gx PGPASSWORD $db_password

# Force drop database
log_message "Step 1: Force dropping database '$db_name'..."
dropdb --host=$db_host --port=$db_port --username=$db_user --force $db_name 2>&1 | tee -a $log_file
set drop_status $status

# dropdb returns 1 if database doesn't exist, which is acceptable
if test $drop_status -ne 0 -a $drop_status -ne 1
    log_message "Error: Failed to drop database (exit code: $drop_status)"
    exit 1
end

if test $drop_status -eq 0
    log_message "Database dropped successfully"
else
    log_message "Database did not exist (this is OK)"
end
log_message ""

# Create database
log_message "Step 2: Creating database '$db_name'..."
createdb --host=$db_host --port=$db_port --username=$db_user $db_name 2>&1 | tee -a $log_file
if test $status -ne 0
    log_message "Error: Failed to create database"
    exit 1
end
log_message "Database created successfully"
log_message ""

# Detect backup format
set backup_ext (string lower (path extension $backup_file))
set backup_format "unknown"

if test "$backup_ext" = ".sql"
    set backup_format "sql"
else if test "$backup_ext" = ".dump"
    set backup_format "custom"
else
    # Try to detect by file content (check for pg_dump header)
    if head -c 5 $backup_file | string match -q "PGDMP"
        set backup_format "custom"
    else
        # Assume SQL format if we can't determine
        set backup_format "sql"
        log_message "Warning: Could not determine backup format from extension, assuming SQL format"
    end
end

log_message "Detected backup format: $backup_format"
log_message ""

# Restore backup
log_message "Step 3: Restoring backup from '$backup_file'..."
log_message "Log from pg_restore:"

pg_restore --host=$db_host --port=$db_port --username=$db_user --dbname=$db_name --verbose --no-owner --no-acl $backup_file &>> $log_file

if test $status -ne 0
    log_message "Error: Failed to restore backup"
    exit 1
end

log_message ""
log_message "=== Restore completed successfully ==="
log_message "Completed at: "(date)
log_message "Log file: $log_file"
