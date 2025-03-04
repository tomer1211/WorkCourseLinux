#!/usr/bin/env bash
#
# run_plants.sh - A Bash script to:
#  1) Create and/or activate a virtual environment outside the repo
#  2) Install needed Python libraries (if not installed)
#  3) Read a CSV file (passed as argument), line by line
#  4) For each plant, run a Python script that generates plots
#  5) Create a folder named after the plant and move plots there
#  6) Log all steps and commit/push changes to GitHub

# -----------------------------------------------------------------------------
# 0. Initial Setup
# -----------------------------------------------------------------------------

# Log file for this script (stores progress, errors, etc.)
LOG_FILE="run_plants.log"

# Virtual environment path OUTSIDE the repository
# Adjust the path as you prefer:
ENV_PATH="$HOME/plant_venv"

# Check that a CSV path was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <CSV_FILE_PATH>"
  exit 1
fi

CSV_FILE="$1"

# -----------------------------------------------------------------------------
# 1. Create / Activate the Virtual Environment
# -----------------------------------------------------------------------------

echo "[$(date)] Checking for virtual environment at $ENV_PATH..." | tee -a "$LOG_FILE"
if [ ! -d "$ENV_PATH" ]; then
  echo "[$(date)] Creating new virtual environment at $ENV_PATH..." | tee -a "$LOG_FILE"
  python3 -m venv "$ENV_PATH"
  if [ $? -ne 0 ]; then
    echo "[$(date)] ERROR: Failed to create virtual environment." | tee -a "$LOG_FILE"
    exit 1
  fi
else
  echo "[$(date)] Virtual environment already exists." | tee -a "$LOG_FILE"
fi

# Activate the venv
# shellcheck source=/dev/null
source "$ENV_PATH/bin/activate"

# -----------------------------------------------------------------------------
# 2. Install Required Libraries (if not already installed)
#    Adjust the libraries as needed for your plant_plots.py script.
# -----------------------------------------------------------------------------
echo "[$(date)] Installing required libraries (numpy, matplotlib, etc.)..." | tee -a "$LOG_FILE"
pip install --upgrade pip
pip install numpy matplotlib

if [ $? -ne 0 ]; then
  echo "[$(date)] ERROR: Failed to install required libraries." | tee -a "$LOG_FILE"
  exit 1
fi

# -----------------------------------------------------------------------------
# 3. Read CSV and Run Python Code for Each Plant
# -----------------------------------------------------------------------------
# CSV format example (header + data lines):
# Plant,Height,Leaf Count,Dry Weight
# Rose,"50 55 60 65 70","35 40 45 50 55","2.0 2.2 2.5 2.7 3.0"
#
# We'll skip the header line. Adjust parsing if your CSV is different.

echo "[$(date)] Processing CSV file: $CSV_FILE" | tee -a "$LOG_FILE"

# Make sure Q4 folder exists (in case we run this script from the repo root)
mkdir -p Q4

# Read the file line by line
# Skip the header by checking if the line starts with "Plant,"
while IFS= read -r line; do

  # Skip empty lines
  if [ -z "$line" ]; then
    continue
  fi

  # Skip header if it starts with "Plant"
  if [[ "$line" == Plant,* ]]; then
    continue
  fi

  # Extract columns (assuming 4 columns: Plant,Height,Leaf Count,Dry Weight)
  # Remove surrounding quotes with tr -d '"'
  plant=$(echo "$line" | cut -d, -f1 | tr -d '"')
  height=$(echo "$line" | cut -d, -f2 | tr -d '"')
  leaf=$(echo "$line" | cut -d, -f3 | tr -d '"')
  weight=$(echo "$line" | cut -d, -f4 | tr -d '"')

  echo "[$(date)] Running Python for plant='$plant'" | tee -a "$LOG_FILE"

  # Run the Python script (adjust the name/arguments if needed)
  python3 plant_plots.py \
    --plant "$plant" \
    -height $height \
    --leaf_count $leaf \
    --dry_weight $weight

  # Check if Python script succeeded
  if [ $? -ne 0 ]; then
    echo "[$(date)] ERROR: Python script failed for $plant" | tee -a "$LOG_FILE"
    # We can continue or exit; choose your logic. We'll continue:
    continue
  fi

  # Create a folder named after the plant inside Q4
  mkdir -p "Q4/$plant"

  # Move the generated PNG files to Q4/$plant
  # Typically, the script creates files like "Rose_height.png", "Rose_leaf_count.png", "Rose_dry_weight.png"
  mv "${plant}_height.png" "Q4/$plant/" 2>>"$LOG_FILE"
  mv "${plant}_leaf_count.png" "Q4/$plant/" 2>>"$LOG_FILE"
  mv "${plant}_dry_weight.png" "Q4/$plant/" 2>>"$LOG_FILE"

  echo "[$(date)] Plots for $plant moved to Q4/$plant" | tee -a "$LOG_FILE"

done < "$CSV_FILE"

# -----------------------------------------------------------------------------
# 4. Deactivate venv (optional)
# -----------------------------------------------------------------------------
deactivate

# -----------------------------------------------------------------------------
# 5. Commit and Push Changes in Q4
# -----------------------------------------------------------------------------
echo "[$(date)] Committing and pushing changes in Q4 folder to GitHub..." | tee -a "$LOG_FILE"
git add Q4
git commit -m "Add generated plant plots from run_plants.sh"
git push

if [ $? -ne 0 ]; then
  echo "[$(date)] ERROR: Failed to push changes to GitHub." | tee -a "$LOG_FILE"
  exit 1
fi

echo "[$(date)] Script completed successfully!" | tee -a "$LOG_FILE"
