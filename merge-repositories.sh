#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Configuration variables
NEW_REPO_NAME=$(basename $(pwd))
GITHUB_USERNAME=""  # Will be set by user input
BACKUP_DIR="../${NEW_REPO_NAME}_backup_$(date +%Y%m%d%H%M%S)"
REPOS_TO_MERGE=()
PROCESSED_REPOS=()

# Function to display error messages and exit
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Function to rollback changes if something goes wrong
rollback() {
    echo "ERROR: $1" >&2
    echo "Rolling back changes..."
    
    # Remove any changes made to the current repository
    git reset --hard HEAD
    
    # Restore from backup if it exists
    if [ -d "$BACKUP_DIR" ]; then
        echo "Restoring from backup at $BACKUP_DIR"
        rm -rf .git
        cp -r "$BACKUP_DIR/.git" .
    fi
    
    exit 1
}

# Check if current directory is a git repository
if [ ! -d ".git" ]; then
    error_exit "Current directory is not a git repository. Please run this script from the root of your new repository."
fi

# Ask for GitHub username
read -p "Enter your GitHub username: " GITHUB_USERNAME
if [ -z "$GITHUB_USERNAME" ]; then
    error_exit "GitHub username cannot be empty."
fi

# Create backup of the current repository
echo "Creating backup of the current repository..."
mkdir -p "$BACKUP_DIR"
cp -r .git "$BACKUP_DIR/"

# Get list of directories in the parent folder (potential repositories to merge)
echo "Scanning parent directory for repositories..."
for dir in ../*/; do
    dir_name=$(basename "$dir")
    # Skip the current repository and the backup directory
    if [ "$dir_name" != "$NEW_REPO_NAME" ] && [ "$dir_name" != "$(basename "$BACKUP_DIR")" ]; then
        # Check if the directory is a git repository
        if [ -d "$dir/.git" ]; then
            REPOS_TO_MERGE+=("$dir_name")
        fi
    fi
done

# Display repositories found
echo "Found the following repositories:"
for repo in "${REPOS_TO_MERGE[@]}"; do
    echo "- $repo"
done

echo ""
echo "This script will merge the above repositories into $NEW_REPO_NAME while preserving their history."
read -p "Do you want to continue? (y/n): " confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Operation cancelled."
    exit 0
fi

# Process each repository
for repo in "${REPOS_TO_MERGE[@]}"; do
    echo ""
    echo "Processing repository: $repo"
    
    # Check if repository exists and is a git repository
    if [ ! -d "../$repo/.git" ]; then
        echo "WARNING: $repo is not a git repository or doesn't exist. Skipping."
        continue
    fi
    
    # Check if a directory with the same name already exists in the current repository
    if [ -d "$repo" ]; then
        read -p "Directory $repo already exists. Overwrite? (y/n): " overwrite
        if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
            echo "Skipping $repo"
            continue
        fi
        rm -rf "$repo"
    fi
    
    # Add the repository as a remote and fetch its contents
    echo "Adding remote for $repo..."
    if ! git remote add "$repo" "../$repo" 2>/dev/null; then
        echo "Remote $repo already exists. Removing and re-adding..."
        git remote remove "$repo"
        if ! git remote add "$repo" "../$repo"; then
            rollback "Failed to add remote for $repo"
        fi
    fi
    
    echo "Fetching repository $repo..."
    if ! git fetch "$repo"; then
        rollback "Failed to fetch repository $repo"
    fi
    
    # Create a branch to track the remote repository's main branch
    # Try common branch names: main, master
    BRANCH_NAME=""
    for branch in main master; do
        if git show-ref --verify --quiet "refs/remotes/$repo/$branch"; then
            BRANCH_NAME="$branch"
            break
        fi
    done
    
    if [ -z "$BRANCH_NAME" ]; then
        # Get the default branch from the repository
        cd "../$repo"
        BRANCH_NAME=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
        cd - > /dev/null
        
        if [ -z "$BRANCH_NAME" ]; then
            echo "WARNING: Could not determine default branch for $repo. Skipping."
            git remote remove "$repo"
            continue
        fi
    fi
    
    echo "Using branch: $BRANCH_NAME for repository $repo"
    
    # Add the repository as a subtree
    echo "Adding $repo as a subtree..."
    if ! git subtree add --prefix="$repo" "$repo/$BRANCH_NAME" --squash; then
        rollback "Failed to add $repo as a subtree"
    fi
    
    # Remove the remote
    git remote remove "$repo"
    
    PROCESSED_REPOS+=("$repo")
    echo "Repository $repo successfully merged."
done

# Push changes to GitHub
echo ""
echo "All repositories have been merged successfully:"
for repo in "${PROCESSED_REPOS[@]}"; do
    echo "- $repo"
done

read -p "Do you want to push changes to GitHub? (y/n): " push_changes

if [ "$push_changes" == "y" ] || [ "$push_changes" == "Y" ]; then
    echo "Pushing changes to GitHub..."
    
    # Check if remote 'origin' exists
    if ! git config remote.origin.url >/dev/null; then
        echo "Remote 'origin' not found. Adding origin..."
        if ! git remote add origin "git@github.com:$GITHUB_USERNAME/$NEW_REPO_NAME.git"; then
            rollback "Failed to add remote origin"
        fi
    fi
    
    # Get current branch name
    CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [ -z "$CURRENT_BRANCH" ]; then
        CURRENT_BRANCH="main"
    fi
    
    # Push to GitHub
    echo "Pushing to branch $CURRENT_BRANCH..."
    if ! git push -u origin "$CURRENT_BRANCH"; then
        rollback "Failed to push to GitHub. Check your SSH keys and repository permissions."
    fi
    
    echo "Changes successfully pushed to GitHub repository: $GITHUB_USERNAME/$NEW_REPO_NAME"
else
    echo "Changes were not pushed to GitHub."
fi

echo ""
echo "Operation completed successfully."
echo "Your repositories have been merged into $NEW_REPO_NAME while preserving their history."
echo "A backup of the original state was created at: $BACKUP_DIR"
