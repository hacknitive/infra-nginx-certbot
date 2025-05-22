#!/bin/bash

# Get the current date and time in ISO format (YYYYMMDD)
current_datetime=$(date +"%Y%m%d")

# Get the current branch name
echo "=============================== Detect current branch"
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ $? -ne 0 ] || [ -z "$current_branch" ]; then
    echo "Error: Could not determine the current branch."
    exit 1
fi
echo "Current branch is $current_branch"

# Display the git status
echo "=============================== status"
git status

# Stage all changes
echo "=============================== add"
git add --all

# Prompt the user for a commit message
echo "=============================== commit"
read -p "Enter commit message: " commit_message

# Use the user-provided commit message
if [ -z "$commit_message" ]; then
    echo "No commit message provided. Using default date as commit message."
    commit_message="$current_datetime"
fi

git commit -am "$commit_message"

echo "=============================== add remotes"
# Define remotes and their URLs in an associative array
declare -A remotes=(
    ["github"]="git@github.com:hacknitive/infra-nginx.git"
    ["gitlab"]="git@gitlab.com:hacknitive/infra-nginx.git"
)

# Ensure the remotes are added
for remote in "${!remotes[@]}"; do
    echo "=============================== Check if $remote remote exists"

    # Check if the remote exists by searching for the remote name
    if ! git remote | grep -q "^$remote$"; then
        # If the remote doesn't exist, add it using the URL from the array
        echo "$remote remote not found. Adding $remote..."
        git remote add "$remote" "${remotes[$remote]}"
        if [ $? -ne 0 ]; then
            # If adding the remote fails, print an error and exit
            echo "Error: Failed to add $remote remote."
            exit 1
        fi
    else
        # If the remote already exists, just print a message
        echo "$remote remote already exists."
    fi
done

# Push to the remote repositories
echo "=============================== push"
# Push the changes and the new tag to the remotes
for remote in "${!remotes[@]}"; do
    echo "=============================== Push to $remote on branch $current_branch"
    # Push the current branch and tags to the remote repository
    if ! git push --tags "$remote" "$current_branch"; then
        # If the push fails, print an error and exit
        echo "Error: Failed to push to $remote on branch $current_branch."
        exit 1
    fi
done

# Print a success message
echo "=============================== Done."