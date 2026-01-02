#!/bin/bash

# Claude Code Status Line Script
# Mimics bash PS1: '[\u \W] branch* $'
# Shows: [username shortdir] branchname* $
# * = modified files, % = untracked files

# Read JSON input from stdin
input=$(cat)

# Extract current working directory
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')

# Fallback to PWD if no cwd in JSON
if [ -z "$cwd" ]; then
    cwd="$PWD"
fi

# Get basename of directory (like \W in PS1)
shortdir=$(basename "$cwd")

# Get username
user=$(whoami)

# Initialize git status
git_info=""

# Check if we're in a git repository
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    # Get current branch name (use --no-optional-locks to avoid lock files)
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || \
             git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)

    if [ -n "$branch" ]; then
        # Check for modified files (dirty state)
        dirty=""
        if ! git -C "$cwd" --no-optional-locks diff --no-ext-diff --quiet --exit-code 2>/dev/null; then
            dirty="*"
        elif ! git -C "$cwd" --no-optional-locks diff --no-ext-diff --cached --quiet --exit-code 2>/dev/null; then
            dirty="*"
        fi

        # Check for untracked files
        untracked=""
        if [ -n "$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | head -1)" ]; then
            untracked="%"
        fi

        git_info=" $branch$dirty$untracked"
    fi
fi

# Output status line: [username shortdir] branch* $
printf "[%s %s]%s \$ " "$user" "$shortdir" "$git_info"
