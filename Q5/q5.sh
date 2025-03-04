#!/usr/bin/env bash
#
# q5.sh - A Bash script to manage a CSV file with a menu-driven interface.
#         Outputs are appended to 5_output.txt in the same folder (Q5).
#
# CSV format example:
# Date collected,Species,Sex,Weight
# 1/8,PF,M,7
# 1/8,OT,M,24
# ...

OUTPUT_FILE="5_output.txt"
LAST_OUTPUT=""     # Holds the last displayed output (for "save last output to new csv")
CSV_FILE=""        # Will hold the name/path of the CSV

# Make sure we're in the script's directory so we write to local 5_output.txt
cd "$(dirname "$0")"

########################################
# Helper: Write output to console & log
########################################
log() {
  echo "$1"
  echo "$1" >> "$OUTPUT_FILE"
}

########################################
# 1) Create CSV by name
########################################
create_csv() {
  read -rp "Enter the name of the CSV file (e.g. data.csv): " CSV_FILE
  if [ -z "$CSV_FILE" ]; then
    log "No CSV file name provided."
    return
  fi

  # Create a basic header row
  echo "Date collected,Species,Sex,Weight" > "$CSV_FILE"
  log "Created CSV file: $CSV_FILE with header."
}

########################################
# 2) Display all CSV data with row index
########################################
display_csv() {
  if [ ! -f "$CSV_FILE" ]; then
    log "CSV file '$CSV_FILE' does not exist. Please create or specify it first."
    return
  fi

  # Number each line (excluding header), but show header as line 0
  # We can do this in multiple ways. For simplicity, use awk:
  #   Print header with line 0, then number subsequent lines starting from 1.
  LAST_OUTPUT=$(awk 'NR==1 {print "Index: 0 => " $0; next} {print "Index: " NR-1 " => " $0}' "$CSV_FILE")
  log "$LAST_OUTPUT"
}

########################################
# 3) Add a new row from user input
########################################
add_row() {
  if [ ! -f "$CSV_FILE" ]; then
    log "CSV file '$CSV_FILE' does not exist. Please create or specify it first."
    return
  fi

  read -rp "Enter Date collected (e.g. 1/8): " date_collected
  read -rp "Enter Species (e.g. PF, OT, etc.): " species
  read -rp "Enter Sex (M/F): " sex
  read -rp "Enter Weight (integer or number): " weight

  # Basic validation
  if [ -z "$date_collected" ] || [ -z "$species" ] || [ -z "$sex" ] || [ -z "$weight" ]; then
    log "One or more fields were empty. Row not added."
    return
  fi

  # Append the row
  echo "$date_collected,$species,$sex,$weight" >> "$CSV_FILE"
  log "Added row: $date_collected,$species,$sex,$weight"
}

########################################
# 4) Read species and display all items + average weight
########################################
filter_by_species() {
  if [ ! -f "$CSV_FILE" ]; then
    log "CSV file '$CSV_FILE' does not exist."
    return
  fi

  read -rp "Enter Species to filter (e.g. OT): " filter_sp
  if [ -z "$filter_sp" ]; then
    log "No species provided."
    return
  fi

  # We skip header (NR>1). Filter lines with 2nd column == filter_sp
  # Print them, and also compute average weight (4th column).
  # We'll use awk for that:
  # 1) Gather lines
  # 2) Sum weight, count lines
  # 3) Print lines + average

  # lines_var will store matching lines
  # avg_var will store the average weight
  IFS=$'\n' read -rd '' lines_var <<< "$(awk -F, -v sp="$filter_sp" 'NR>1 && $2 == sp {print $0}' "$CSV_FILE")"
  count=$(awk -F, -v sp="$filter_sp" 'NR>1 && $2 == sp {c++; sum+=$4} END { if(c>0) print c; else print 0 }' "$CSV_FILE")
  sum=$(awk -F, -v sp="$filter_sp" 'NR>1 && $2 == sp {c++; sum+=$4} END {print sum}' "$CSV_FILE")

  if [ "$count" -eq 0 ]; then
    LAST_OUTPUT="No rows found for species: $filter_sp"
    log "$LAST_OUTPUT"
    return
  fi

  avg=$(awk -v s="$sum" -v c="$count" 'BEGIN {printf "%.2f", s/c}')
  LAST_OUTPUT="Rows for species=$filter_sp:\n$lines_var\nAverage Weight: $avg"
  log "$LAST_OUTPUT"
}

########################################
# 5) Read species + sex => display items
########################################
filter_by_species_sex() {
  if [ ! -f "$CSV_FILE" ]; then
    log "CSV file '$CSV_FILE' does not exist."
    return
  fi

  read -rp "Enter Species (e.g. OT): " filter_sp
  read -rp "Enter Sex (M/F): " filter_sex
  if [ -z "$filter_sp" ] || [ -z "$filter_sex" ]; then
    log "Missing species or sex."
    return
  fi

  # Filter lines where 2nd column == filter_sp AND 3rd column == filter_sex
  IFS=$'\n' read -rd '' lines_var <<< "$(awk -F, -v sp="$filter_sp" -v sx="$filter_sex" 'NR>1 && $2 == sp && $3 == sx {print $0}' "$CSV_FILE")"
  if [ -z "$lines_var" ]; then
    LAST_OUTPUT="No rows found for species=$filter_sp and sex=$filter_sex"
  else
    LAST_OUTPUT="Rows for species=$filter_sp, sex=$filter_sex:\n$lines_var"
  fi
  log "$LAST_OUTPUT"
}

########################################
# 6) Save LAST_OUTPUT to new CSV
########################################
save_last_output() {
  if [ -z "$LAST_OUTPUT" ]; then
    log "No output to save. Perform an operation first."
    return
  fi

  read -rp "Enter the new CSV filename: " new_csv
  if [ -z "$new_csv" ]; then
    log "No file name provided."
    return
  fi

  # We'll save only the lines from LAST_OUTPUT that look like CSV
  # For simplicity, assume lines with commas are CSV data
  echo "Date collected,Species,Sex,Weight" > "$new_csv"

  # Filter lines with a comma. If your output includes lines that are not CSV, adjust as needed.
  echo "$LAST_OUTPUT" | grep ',' >> "$new_csv"

  log "Saved LAST_OUTPUT to $new_csv"
}

########################################
# 7) Delete row by row index
########################################
delete_by_index() {
  if [ ! -f "$CSV_FILE" ]; then
    log "CSV file '$CSV_FILE' does not exist."
    return
  fi

  display_csv  # show the user the indexed lines
  read -rp "Enter the row index to delete (as shown in display_csv): " del_idx

  # We skip the header as index=0, so for the body:
  #  If user says "1", that means the first data line after header
  # We'll use sed to delete line (del_idx+1) from the file
  # Because the header is line 1 in the file, so data line #1 is line 2 in the file, etc.
  # So the file line to delete is (del_idx + 1).

  # Validate it's an integer
  if [[ ! "$del_idx" =~ ^[0-9]+$ ]]; then
    log "Invalid index."
    return
  fi

  # We'll check if del_idx=0 => that's the header
  if [ "$del_idx" -eq 0 ]; then
    log "Cannot delete header line. Operation canceled."
    return
  fi

  # We'll do a quick line count
  total_lines=$(wc -l < "$CSV_FILE")
  # If the user tries to delete beyond the last data line
  if [ "$del_idx" -ge "$total_lines" ]; then
    log "Index out of range."
    return
  fi

  sed -i "$((del_idx+1))d" "$CSV_FILE"
  log "Deleted row index $del_idx from $CSV_FILE."
}

########################################
# 8) Update weight by row index
########################################
update_weight() {
  if [ ! -f "$CSV_FILE" ]; then
    log "CSV file '$CSV_FILE' does not exist."
    return
  fi

  display_csv
  read -rp "Enter the row index to update (weight): " upd_idx
  if [[ ! "$upd_idx" =~ ^[0-9]+$ ]]; then
    log "Invalid index."
    return
  fi
  if [ "$upd_idx" -eq 0 ]; then
    log "Cannot update header line."
    return
  fi

  read -rp "Enter the new weight: " new_weight
  if [ -z "$new_weight" ]; then
    log "No weight provided."
    return
  fi

  # We'll do a quick line count check
  total_lines=$(wc -l < "$CSV_FILE")
  if [ "$upd_idx" -ge "$total_lines" ]; then
    log "Index out of range."
    return
  fi

  # Approach: parse the line, replace the 4th column with new_weight
  # We can do this with sed + awk, but let's do a small trick:
  # We'll transform only line (upd_idx+1) in place.
  # Example approach with sed capturing groups:
  # sed -i "<line_number> s/^\([^,]*,[^,]*,[^,]*,\).*/\1new_weight/"
  # But we must preserve the rest of the line if there's anything else.

  # Actually, let's do a more direct approach with awk if needed. 
  # But we'll do it in sed for brevity:
  line_number=$((upd_idx+1))
  sed -i "${line_number}s/^\([^,]*,[^,]*,[^,]*,\).*/\1$new_weight/" "$CSV_FILE"

  log "Updated weight at row index $upd_idx to $new_weight."
}

########################################
# Main Menu Loop
########################################
while true; do
  echo "-------------------------------------"
  echo "Q5 Menu - CSV Management"
  echo "CSV File: $CSV_FILE"
  echo "1) Create CSV by name"
  echo "2) Display all CSV data with row index"
  echo "3) Add a new row from user input"
  echo "4) Filter by species + show average weight"
  echo "5) Filter by species & sex"
  echo "6) Save last output to new CSV"
  echo "7) Delete row by row index"
  echo "8) Update weight by row index"
  echo "9) Exit"
  echo "-------------------------------------"
  read -rp "Choose an option: " choice

  case "$choice" in
    1) create_csv ;;
    2) display_csv ;;
    3) add_row ;;
    4) filter_by_species ;;
    5) filter_by_species_sex ;;
    6) save_last_output ;;
    7) delete_by_index ;;
    8) update_weight ;;
    9) 
       log "Exiting Q5 script."
       break
       ;;
    *)
       log "Invalid choice."
       ;;
  esac
done

# End of script
