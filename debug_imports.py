import sys
import os
print(f"CWD: {os.getcwd()}")
print(f"Path: {sys.path}")
try:
    import backend.artifacts.io
    print("SUCCESS: backend.artifacts.io imported")
    print(f"FILE: {backend.artifacts.io.__file__}")
except Exception as e:
    print(f"FAIL: {e}")

try:
    from backend.agms_foundation import AGMSFoundation
    print("SUCCESS: AGMSFoundation imported")
except Exception as e:
    print(f"FAIL AGMS: {e}")
