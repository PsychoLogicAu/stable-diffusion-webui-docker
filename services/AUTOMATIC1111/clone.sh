#!/bin/bash

set -Eeuox pipefail

repository_name="$1"
repository_url="$2"
tag_or_sha="$3"

mkdir -p "/repositories/$repository_name"
cd "/repositories/$repository_name"

git init
git remote add origin "$repository_url"
git fetch origin "$tag_or_sha" --depth=1

# Check if the provided argument is a tag or a commit hash
if git rev-parse "$tag_or_sha" >/dev/null 2>&1; then
    # If it's a commit hash
    git reset --hard "$tag_or_sha"
else
    # If it's a tag
    git checkout "$tag_or_sha"
fi

# Remove the git directory to clean up
rm -rf .git
