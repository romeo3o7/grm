import os
import sys
import requests
from update import upall

def main():
    cmd = sys.argv[1]
    ghtoken = os.getenv("GITHUB_TOKEN", "").strip()
    headers = {
            "User-Agent": "grm/1.0",
            "Accept": "application/vnd.github+json",
            **({"Authorization": f"Bearer {ghtoken}"} if ghtoken else {})
        }
    with requests.Session() as session:
        session.headers.update(headers)
        if cmd == "install":
            raise SystemExit(f"install {sys.argv[2]}")
        if cmd == "update":
            upall(session)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        raise SystemExit("\nGRM interrupted.")
