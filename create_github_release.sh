#!/bin/bash

echo "PulseChain Full Node Suite - GitHub Repository Setup"
echo "==================================================="
echo ""
echo "This script will help you set up your GitHub repository and"
echo "create a pre-pre-release version (v0.1.0) of your codebase."
echo ""
echo "⚠️ Prerequisites:"
echo "- A GitHub account"
echo "- Git installed on your system"
echo "- GitHub CLI (gh) installed (optional, for creating releases)"
echo ""

# Get the current directory
CURRENT_DIR=$(pwd)
REPO_NAME="PulseChain-Full-Node-Suite"
GITHUB_USERNAME="MaximCincinnatis"

# Set version information
VERSION="0.1.0"

echo "Step 1: Creating a backup of your codebase"
echo "-----------------------------------------"

# Create a backup directory if it doesn't exist
if [ ! -d "backup_for_git" ]; then
  mkdir -p backup_for_git
  echo "Created backup_for_git directory."
else
  echo "backup_for_git directory already exists."
fi

# Copy all files to the backup directory
echo "Copying files to backup_for_git..."
cp -r * backup_for_git/ 2>/dev/null || true
cp .[!.]* backup_for_git/ 2>/dev/null || true

echo ""
echo "Step 2: Setting up the Git repository"
echo "----------------------------------"

cd backup_for_git

# Initialize Git repository if not already initialized
if [ ! -d ".git" ]; then
  git init
  echo "Initialized new Git repository."
else
  echo "Git repository already initialized."
fi

# Add all files to Git
git add .

# Commit the files
git commit -m "Initial commit: PulseChain Full Node Suite pre-pre-release"

# Set the default branch to main
git branch -M main

echo ""
echo "Step 3: Add GitHub remote repository"
echo "---------------------------------"

# Check if remote origin already exists
if git remote | grep -q "origin"; then
  echo "Remote 'origin' already exists. Updating URL..."
  git remote set-url origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
else
  echo "Adding remote 'origin'..."
  git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
fi

echo ""
echo "Step 4: Push to GitHub"
echo "-------------------"
echo "To push your code to GitHub, you need to:"
echo "1. Create a repository named '$REPO_NAME' on GitHub"
echo "   Visit: https://github.com/new"
echo ""
echo "2. Run the following command to push your code:"
echo "   cd backup_for_git && git push -u origin main"
echo ""

# Check if GitHub CLI is installed
if command -v gh &> /dev/null; then
  echo "Step 5: Create a pre-release (requires GitHub CLI)"
  echo "----------------------------------------------"
  echo "To create a pre-release on GitHub, run:"
  echo "cd backup_for_git && gh release create v$VERSION --prerelease --title 'Pre-Pre-Release v$VERSION' --notes-file RELEASE_NOTES.md"
else
  echo "Step 5: Create a pre-release (manual steps)"
  echo "--------------------------------------"
  echo "After pushing your code, visit:"
  echo "https://github.com/$GITHUB_USERNAME/$REPO_NAME/releases/new"
  echo ""
  echo "Create a new release with:"
  echo "- Tag version: v$VERSION"
  echo "- Release title: Pre-Pre-Release v$VERSION"
  echo "- Description: Copy content from RELEASE_NOTES.md"
  echo "- Check 'This is a pre-release' box"
fi

echo ""
echo "Final Steps:"
echo "-----------"
echo "1. Verify your repository is set up correctly"
echo "2. Ensure PRE_RELEASE_README.md is visible in your repository"
echo "3. Test the update_files.sh script to verify it shows the pre-release warnings"
echo ""
echo "Done! Your PulseChain Full Node Suite is now ready for pre-pre-release."

# Return to original directory
cd "$CURRENT_DIR"

# Make the script executable
chmod +x create_github_release.sh 