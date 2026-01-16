
import sys
import os
import json
from fastapi.testclient import TestClient
from backend.api_server import app

client = TestClient(app)

def verify_autofix(label):
    print(f"--- VERIFYING: {label} ---")
    try:
        response = client.get("/autofix")
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(f"Status: {data.get('status')}")
        print("Recommendations:")
        for rec in data.get('recommendations', []):
            print(f"- {rec['action_code']}: {rec['title']}")
        return data
    except Exception as e:
        print(f"Error: {e}")
        return None

if __name__ == "__main__":
    if len(sys.argv) > 1:
        verify_autofix(sys.argv[1])
