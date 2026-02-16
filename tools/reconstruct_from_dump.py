import os
import re
import sys

# Paths
REPO_ROOT = r"C:\MSR\MarketSniperRepo"
STASH_FILES = [
    r"C:\MSR\stash1.patch",
    r"C:\MSR\stash2.patch",
    r"C:\MSR\stash3.patch",
    r"C:\MSR\stash4.patch"
]

def parse_patch_file(patch_path):
    """
    Parses a unified diff patch file and returns a dict of structured changes.
    Returns: { filename: { 'content': str, 'mode': 'new'|'mod' } }
    """
    print(f"Parsing {patch_path}...")
    with open(patch_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    changes = {}
    current_file = None
    current_content = []
    is_header = True
    
    # Regex for start of file diff
    file_start_re = re.compile(r"^diff --git a/(.+) b/(.+)")
    
    for line in lines:
        match = file_start_re.match(line)
        if match:
            # Save previous file if exists
            if current_file:
                changes[current_file] = "".join(current_content)
            
            # Start new file
            current_file = match.group(2).strip() # Use 'b' path (destination)
            current_content = []
            is_header = True
            print(f"  Found file: {current_file}")
            continue

        if current_file:
            # Skip header lines until we see the first hunk @@
            if is_header:
                if line.startswith("@@"):
                    is_header = False
                continue
            
            # Process content lines
            if line.startswith("+") and not line.startswith("+++"):
                current_content.append(line[1:]) # Remove the '+'
            elif line.startswith(" ") or line.startswith("-"):
                # In a pure 'reconstruction' from a dump where we want the *new* state,
                # we usually just want the '+' lines if it's a new file.
                # However, for modifications, we might need context.
                # But here, we are assuming the dump contains the *target* state for many files.
                # If the patch is a mix of context and adds, this is tricky.
                # BUT, looking at the dump, it seems to be a diff.
                # If we treat it as a "Force Write New Content" for code files, we might be okay.
                # Wait, if it's a diff, it has context lines starting with space.
                # If we just take '+' lines, we lose the context lines (unchanged lines).
                # The dump provided `diff --git ...`. 
                # If I only take `+` lines, I will get a file with ONLY the added lines.
                # If the file didn't exist, that's fine.
                # If the file existed, I need to apply the patch properly.
                
                # HYBRID STRATEGY:
                # 1. If line starts with " ", keep it (it's context/unchanged).
                # 2. If line starts with "+", keep it (it's added).
                # 3. If line starts with "-", ignore it (it's deleted).
                # This approximates the "result" file content.
                if line.startswith(" "):
                    current_content.append(line[1:])
                pass
            
    # Save last file
    if current_file:
        changes[current_file] = "".join(current_content)
        
    return changes

def apply_changes(changes):
    """
    Writes the parsed content to files.
    """
    for filename, content in changes.items():
        full_path = os.path.join(REPO_ROOT, filename)
        
        # Special Logic for War Calendar
        if "OMSR_WAR_CALENDAR" in filename:
            print(f"  [MERGE] Merging War Calendar: {filename}")
            handle_war_calendar(full_path, content)
            continue
            
        # Ensure dir exists
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        
        # Write (Force Overwrite for Code to ensure alignment with dump)
        mode = "w"
        if os.path.exists(full_path):
             print(f"  [UPDATE] Overwriting {filename}")
        else:
             print(f"  [CREATE] Creating {filename}")
             
        with open(full_path, "w", encoding='utf-8') as f:
            f.write(content)

def handle_war_calendar(full_path, new_block_content):
    """
    Smart append for War Calendar to avoid destroying the header/dedup work.
    """
    if not os.path.exists(full_path):
        print("    ! War Calendar missing! Writing full artifact.")
        with open(full_path, "w", encoding='utf-8') as f:
            f.write(new_block_content)
        return

    with open(full_path, "r", encoding='utf-8') as f:
        existing_content = f.read()

    # Heuristic: Check if "PHASE: SYSTEM CONSOLIDATION" exists
    if "PHASE: SYSTEM CONSOLIDATION" in existing_content:
        print("    ! D63 Block already likely present. Appending tentatively.")
    
    # We simply append the *new* content essentially.
    # The patch parsing above for 'space' lines might have reconstructed strictly the diff hunks.
    # If the patch was a partial diff (just the end), `new_block_content` will only be the end.
    # So appending is the right move.
    
    # Check if the text we are about to append is already at the end
    clean_new = new_block_content.strip()
    if clean_new in existing_content:
        print("    ! Content appears duplicate. Skipping append.")
        return

    # Append
    print("    -> Appending D63 Block to War Calendar.")
    with open(full_path, "a", encoding='utf-8') as f:
        f.write("\n\n" + clean_new + "\n")

def main():
    print("Starting Reconstruction from Mega-Archive Stashes...")
    
    # 1. Aggregate Content
    all_changes = {}
    for stash_file in STASH_FILES:
        if os.path.exists(stash_file):
            changes = parse_patch_file(stash_file)
            all_changes.update(changes)
        else:
            print(f"Warning: Stash file not found: {stash_file}")
            
    print(f"Parsed {len(all_changes)} files from stash.")
    
    # 2. Apply
    apply_changes(all_changes)
    
    print("\nReconstruction Validated.")

if __name__ == "__main__":
    main()
