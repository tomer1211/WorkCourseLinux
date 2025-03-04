#!/usr/bin/env bash
#
# commits.sh - A script that automates commit messages based on a CSV file and current Git branch.
#
# CSV Format (tasks.csv):
# BUGID,DESCRIPTION,BRANCH,DEVELOPER NAME,BUG PRIORITY,REPOSITORY PATH,GITHUBURL
#
# Commit message format:
# BugID:CurrentDate:Branch:DevName:Priority:Description[:DevComment]
#
# Usage: ./commits.sh [Optional Developer Comment]
#
# All operations are logged to commits.log. The Git history is saved to commits.txt.

CSV_FILE="tasks.csv"
LOG_FILE="commits.log"
HISTORY_FILE="commits.txt"

# Clear (or create) the log file at the start
: > "$LOG_FILE"

echo "Starting commits.sh..." | tee -a "$LOG_FILE"

# 1. Validate the CSV file exists
if [ ! -f "$CSV_FILE" ]; then
  echo "ERROR: CSV file '$CSV_FILE' not found in $(pwd)" | tee -a "$LOG_FILE"
  exit 1
fi
echo "CSV file '$CSV_FILE' found." | tee -a "$LOG_FILE"

# 2. Determine the current Git branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>>"$LOG_FILE")
if [ -z "$BRANCH" ]; then
  echo "ERROR: Unable to determine current git branch." | tee -a "$LOG_FILE"
  exit 1
fi
echo "Current branch: $BRANCH" | tee -a "$LOG_FILE"

# 3. Search the CSV for a matching row (comparing the third column)
ROW=$(awk -F, -v branch="$BRANCH" 'NR>1 && tolower($3)==tolower(branch) {print $0}' "$CSV_FILE")
if [ -z "$ROW" ]; then
  echo "ERROR: No matching row found in CSV for branch '$BRANCH'." | tee -a "$LOG_FILE"
  exit 1
fi
echo "Matching CSV row: $ROW" | tee -a "$LOG_FILE"

# 4. Parse the CSV row into variables.
# Assumes CSV columns: BUGID,DESCRIPTION,BRANCH,DEVELOPER NAME,BUG PRIORITY,REPOSITORY PATH,GITHUBURL
OLDIFS=$IFS
IFS=',' read -r BUGID DESCRIPTION CSV_BRANCH DEVNAME PRIORITY REPO GITHUBURL <<< "$ROW"
IFS=$OLDIFS

# Remove any leading/trailing quotes/spaces from DESCRIPTION
DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/^"//;s/"$//;s/^ *//;s/ *$//')

# 5. Build the commit message
CURR_DATE=$(date '+%Y-%m-%d %H:%M:%S')
DEV_COMMENT=""
if [ $# -ge 1 ]; then
  DEV_COMMENT="$1"
fi

COMMIT_MSG="${BUGID}:${CURR_DATE}:${BRANCH}:${DEVNAME}:${PRIORITY}:${DESCRIPTION}"
if [ -n "$DEV_COMMENT" ]; then
  COMMIT_MSG="${COMMIT_MSG}:${DEV_COMMENT}"
fi

echo "Constructed commit message: $COMMIT_MSG" | tee -a "$LOG_FILE"

# 6. Stage, commit, and push changes
git add . 2>>"$LOG_FILE"
if [ $? -ne 0 ]; then
  echo "ERROR: git add failed." | tee -a "$LOG_FILE"
  exit 1
fi

git commit -m "$COMMIT_MSG" 2>>"$LOG_FILE"
if [ $? -ne 0 ]; then
  echo "ERROR: git commit failed." | tee -a "$LOG_FILE"
  exit 1
fi
echo "Commit succeeded." | tee -a "$LOG_FILE"

git push 2>>"$LOG_FILE"
if [ $? -ne 0 ]; then
  echo "ERROR: git push failed." | tee -a "$LOG_FILE"
  exit 1
fi
echo "Push succeeded." | tee -a "$LOG_FILE"

# 7. Save Git history to commits.txt
git log --oneline > "$HISTORY_FILE"
if [ $? -ne 0 ]; then
  echo "ERROR: Could not write git log to '$HISTORY_FILE'." | tee -a "$LOG_FILE"
  exit 1
fi
echo "Git commit history saved to '$HISTORY_FILE'." | tee -a "$LOG_FILE"

echo "commits.sh completed successfully." | tee -a "$LOG_FILE"
exit 0
