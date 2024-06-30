import sys
import os
import string

def normalize_string(s):
    """Normalize the string by removing spaces and punctuation marks."""
    return ''.join(c for c in s if c.isalnum())

def are_duplicates(line1, line2):
    """Check if two lines are considered duplicates by normalized comparison."""
    return normalize_string(line1) == normalize_string(line2)

def remove_consecutive_duplicates(filename):
    # Check if the file exists
    if not os.path.isfile(filename):
        print(f"File '{filename}' does not exist.")
        return
    
    # Create a backup of the original file
    backup_filename = filename + '.bak'
    os.rename(filename, backup_filename)
    
    # Read the content from the backup file
    with open(backup_filename, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Process the lines to remove consecutive duplicates
    new_lines = []
    previous_line = None
    duplicate_count = 0
    
    for line in lines:
        if previous_line is not None and are_duplicates(line, previous_line):
            duplicate_count += 1
        else:
            duplicate_count = 0
        
        if duplicate_count == 0:
            new_lines.append(line)
        
        previous_line = line
    
    # Write the modified content back to the original file
    with open(filename, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    
    print(f"Processed file saved as '{filename}', backup saved as '{backup_filename}'.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python remove_duplicates.py <filename>")
    else:
        filename = sys.argv[1]
        remove_consecutive_duplicates(filename)
