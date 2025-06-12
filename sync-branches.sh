#!/bin/bash

# sync-branches.sh
# Syncs changes from production -> release -> testing -> dev-* branches
# Usage: ./sync-branches.sh [all|dev-jake]
#   - all: Sync to all dev-* branches
#   - dev-jake: Sync only to dev-jake
#   - No argument: Sync only to dev-jake (default)

set -e  # Exit on error

# Default to syncing only dev-jake
DEV_BRANCHES="dev-jake"
if [[ "$1" == "all" ]]; then
    # Get all dev-* branches
    DEV_BRANCHES=$(git ls-remote --heads origin 'dev-*' | awk '{print $2}' | sed 's|refs/heads/||' | tr '\n' ' ')
    if [[ -z "$DEV_BRANCHES" ]]; then
        echo "❌ No dev-* branches found"
        exit 1
    fi
    echo "Found dev branches: $DEV_BRANCHES"
elif [[ "$1" != "" && "$1" != "dev-jake" ]]; then
    echo "❌ Invalid argument. Use 'all' or 'dev-jake'."
    exit 1
fi

# Function to run a command and check for errors
run_cmd() {
    echo "Running: $@"
    if ! "$@"; then
        echo "❌ Command failed: $@"
        exit 1
    fi
}

# Sync production -> release
run_cmd git checkout production
run_cmd git pull
run_cmd git checkout release
run_cmd git pull
run_cmd git merge production --no-edit
run_cmd git push

# Sync release -> testing
run_cmd git checkout testing
run_cmd git pull
run_cmd git merge release --no-edit
run_cmd git push

# Sync testing -> dev-* branches
for BRANCH in $DEV_BRANCHES; do
    run_cmd git checkout "$BRANCH"
    run_cmd git pull
    run_cmd git merge testing --no-edit
    run_cmd git push
done

echo "✅ Sync completed successfully"