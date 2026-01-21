# PostgreSQL Force Restore

A Fish shell script that force-destroys a PostgreSQL database and rebuilds it from a backup file. This script handles active connections, automatically detects backup formats, and provides comprehensive logging.

## Features

- **Force Database Destruction**: Terminates active connections and drops the database
- **Automatic Format Detection**: Supports SQL dumps (`.sql`) and custom format backups (`.dump`)
- **Comprehensive Logging**: All operations are logged to timestamped log files
- **Strict Error Handling**: Exits immediately on any error for reliable operation
- **Connection String Parsing**: Simple connection string format for easy use

## Requirements

- Fish shell (3.0+)
- PostgreSQL client tools (`dropdb`, `createdb`, `psql`, `pg_restore` for custom format conversion)
- PostgreSQL server access

## Installation

### Option 1: Global Installation (Recommended)

1. Clone or download this repository:
   ```bash
   git clone <repository-url>
   cd pgsql-force-restore
   ```

2. Create a symlink to make it available globally:
   ```bash
   ln -sf $(pwd)/script.fish ~/.local/bin/pgsql-force-restore
   chmod +x script.fish
   ```

   Make sure `~/.local/bin` is in your PATH. If using Fish shell, add this to `~/.config/fish/config.fish`:
   ```fish
   fish_add_path $HOME/.local/bin
   ```

3. Verify installation:
   ```bash
   which pgsql-force-restore
   ```

### Option 2: Direct Usage

Simply run the script directly:
```bash
./script.fish <backup-file> <connection-string> [log-dir]
```

## Usage

```bash
pgsql-force-restore <backup-file> <connection-string> [log-dir]
```

### Arguments

1. **backup-file** (required): Path to the PostgreSQL backup file
   - Absolute path is recommended
   - Supports `.sql` (SQL dump) and `.dump` (custom format) files
   - Auto-detects format based on extension or file content

2. **connection-string** (required): PostgreSQL connection details
   - Format: `<username>:<password>@<host>:<port>/<db-name>`
   - Port defaults to `5432` if not specified
   - Example: `postgres:mypassword@localhost:5432/mydatabase`

3. **log-dir** (optional): Directory for log files
   - Defaults to `./logs` relative to current directory
   - Directory will be created if it doesn't exist

### Examples

**Basic usage:**
```bash
pgsql-force-restore /path/to/backup.sql postgres:mypass@localhost:5432/mydb
```

**With custom log directory:**
```bash
pgsql-force-restore /path/to/backup.dump postgres:mypass@localhost:5432/mydb /var/log/pg-restore
```

**Remote database:**
```bash
pgsql-force-restore backup.sql admin:secret@db.example.com:5432/production
```

**Default port (5432):**
```bash
pgsql-force-restore backup.sql postgres:mypass@localhost/mydb
```

## How It Works

1. **Parse Arguments**: Validates inputs and extracts connection details
2. **Setup Logging**: Creates log directory and initializes timestamped log file
3. **Parse Connection String**: Extracts username, password, host, port, and database name
4. **Validate Backup File**: Checks file existence and readability
5. **Force Drop Database**: Uses `dropdb --force` to terminate connections and drop the database
6. **Create Database**: Creates a fresh database using `createdb`
7. **Detect Backup Format**: Auto-detects SQL or custom format
8. **Restore Backup**: Uses `psql` for all restores (converts custom format to SQL first)

## Logging

All operations are logged to timestamped files in the specified log directory (default: `./logs`):

```
logs/restore_2024-01-21_19-30-45.log
```

Log files include:
- Script start time and arguments
- Parsed connection details
- Each command execution (dropdb, createdb, restore)
- Command outputs (stdout and stderr)
- Script completion status

## Error Handling

The script uses strict error handling:
- Exits immediately on any command failure
- Validates all inputs before proceeding
- Provides clear error messages
- Logs all errors to the log file

## Supported Backup Formats

- **SQL Dumps** (`.sql`): Plain text SQL commands, restored directly with `psql`
- **Custom Format** (`.dump`): PostgreSQL custom format, converted to SQL and restored with `psql`
- **Auto-detection**: Checks file extension and file header to determine format

Note: Both formats are restored using `psql`. Custom format files are automatically converted to SQL format before restoration.

## Security Notes

- Passwords are passed via the `PGPASSWORD` environment variable
- Connection strings contain sensitive information - be cautious with logs
- Consider using PostgreSQL connection files (`.pgpass`) for production use

## Troubleshooting

**Error: Missing required arguments**
- Ensure you provide at least 2 arguments (backup file and connection string)

**Error: Invalid connection string format**
- Verify the format: `username:password@host:port/db-name`
- Ensure special characters in password are properly escaped if needed

**Error: Failed to drop database**
- Check database permissions
- Verify connection details are correct
- Check if database exists (non-existent database is handled gracefully)

**Error: Failed to create database**
- Verify user has `CREATEDB` privilege
- Check connection details

**Error: Failed to restore backup**
- Verify backup file is not corrupted
- Check database user has necessary permissions
- Ensure backup format matches detected format

## License

This script is provided as-is for personal and development use.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
