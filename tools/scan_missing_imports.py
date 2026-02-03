
import os
import ast

TYPING_NAMES = {'Optional', 'List', 'Dict', 'Any', 'Union'}

def scan_file(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            source = f.read()
        tree = ast.parse(source)
    except Exception as e:
        print(f"Error parsing {path}: {e}")
        return

    imported_names = set()
    used_names = set()

    # Check Usage
    for node in ast.walk(tree):
        if isinstance(node, ast.Name):
            if node.id in TYPING_NAMES:
                used_names.add(node.id)
        elif isinstance(node, ast.Subscript):
            # Check value like Optional[...]
            if isinstance(node.value, ast.Name):
                if node.value.id in TYPING_NAMES:
                    used_names.add(node.value.id)
    
    # Check Imports
    for node in ast.walk(tree):
        if isinstance(node, ast.ImportFrom):
            if node.module == 'typing':
                for alias in node.names:
                    imported_names.add(alias.name)
        elif isinstance(node, ast.Import):
            for alias in node.names:
                if alias.name == 'typing':
                    # If generic import typing, assumption is typing.List usage, 
                    # but our scanner checks for bare Names. 
                    # If code uses List without import typing, it expects from typing import List.
                    pass

    missing = used_names - imported_names
    if missing:
        print(f"{path}: Missing {missing}")

def main():
    start_dir = "backend"
    for root, dirs, files in os.walk(start_dir):
        for name in files:
            if name.endswith(".py"):
                path = os.path.join(root, name)
                scan_file(path)

if __name__ == "__main__":
    main()
