#!/usr/bin/env bash
# commit.sh: A small script to commit with a custom message

if [ -z "$1" ]; then
  echo "Usage: ./commit.sh \"Commit message\""
  exit 1
fi

# Append commit message to a local commit_log.txt (optional)
echo "$(date): $1" >> commit_log.txt

# Stage and commit
git add .
git commit -m "$1"
