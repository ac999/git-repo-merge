# Repository Merger Script

## Overview

`merge-repositories.sh` is a robust Bash script designed to safely merge multiple Git repositories into a single repository while preserving their commit history. The script provides a guided, interactive process with safety mechanisms including backups and rollback capabilities.

## Features

- **Safe Merging**: Preserves the complete Git history of each merged repository
- **Interactive Process**: Guides users through each step with clear prompts
- **Backup System**: Creates automatic backups before making changes
- **Error Handling**: Comprehensive error checking with rollback functionality
- **Flexible Branch Detection**: Works with both `main` and `master` default branches
- **GitHub Integration**: Option to push merged repository to GitHub

## Prerequisites

- Bash shell (tested on Linux and macOS)
- Git installed and configured
- GitHub account (if pushing to GitHub)
- SSH keys configured for GitHub (if pushing via SSH)

## Usage

1. **Prepare your environment**:
   - Create a new Git repository that will serve as the destination for merging
   - Place this repository in a directory alongside the repositories you want to merge

2. **Run the script**:
   ```bash
   chmod +x merge-repositories.sh
   ./merge-repositories.sh
   ```

3. **Follow the interactive prompts**:
   - Enter your GitHub username when prompted
   - Review the list of detected repositories
   - Confirm the merge operation
   - Choose whether to push to GitHub when complete

## How It Works

1. **Initialization**:
   - Verifies the current directory is a Git repository
   - Creates a timestamped backup of the original repository state

2. **Repository Detection**:
   - Scans the parent directory for other Git repositories
   - Excludes the current repository and backup directories

3. **Merging Process**:
   - For each repository:
     - Adds it as a remote
     - Fetches its contents
     - Detects the default branch (main/master)
     - Adds it as a subtree with preserved history
     - Removes the temporary remote

4. **Completion**:
   - Provides a summary of merged repositories
   - Offers to push changes to GitHub
   - Displays backup location information

## Safety Features

- **Automatic Backup**: Creates a complete backup of the `.git` directory before making changes
- **Rollback Mechanism**: Automatically restores from backup if any step fails
- **Conflict Prevention**: Checks for existing directories and prompts before overwriting
- **Error Handling**: Exits immediately on errors with descriptive messages

## Example Workflow

```bash
# Create new repository to serve as merge destination
mkdir combined-repo
cd combined-repo
git init

# Run the merger script (from the new repository)
../merge-repositories.sh

# Follow the interactive prompts to:
# 1. Enter GitHub username
# 2. Review repositories to merge
# 3. Confirm the operation
# 4. Choose to push to GitHub
```

## Output

After successful execution, the script will:
1. Display a list of all successfully merged repositories
2. Show the location of the backup directory
3. Provide the GitHub repository URL if changes were pushed

## Limitations

- Currently supports merging repositories from the local filesystem only
- Requires all repositories to be in the same parent directory
- Does not handle complex merge conflicts (though these are rare with subtree merges)

## License

This script is provided under the MIT License. See [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please open an issue or pull request for any improvements or bug fixes.
