
import json
import sys

def main():
    try:
        with open('artifacts/audit/local_openapi.json', 'r') as f:
            local = json.load(f)
        with open('artifacts/audit/prod_openapi.json', 'r') as f:
            prod = json.load(f)

        local_paths = set(local.get('paths', {}).keys())
        prod_paths = set(prod.get('paths', {}).keys())

        missing = sorted(list(local_paths - prod_paths))
        extra = sorted(list(prod_paths - local_paths))
        common = sorted(list(local_paths & prod_paths))

        with open('artifacts/audit/missing_matrix.txt', 'w') as f:
            f.write("=== MISSING IN PROD (Present Locally) ===\n")
            for p in missing:
                f.write(f"{p}\n")
            
            f.write("\n=== EXTRA IN PROD (Missing Locally??) ===\n")
            for p in extra:
                f.write(f"{p}\n")

            f.write(f"\n=== SUMMARY ===\nLocal Routes: {len(local_paths)}\nProd Routes: {len(prod_paths)}\nMissing: {len(missing)}\nCommon: {len(common)}\n")

        print(f"Generated artifacts/audit/missing_matrix.txt. Missing: {len(missing)}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
