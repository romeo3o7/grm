import os
import requests
from update import upall

def main():
    ghtoken = os.getenv("GITHUB_TOKEN", "").strip()
    headers = {
            "User-Agent": "grm/1.0",
            "Accept": "application/vnd.github+json",
            **({"Authorization": f"Bearer {ghtoken}"} if ghtoken else {})
        }
    with requests.Session() as session:
        session.headers.update(headers)
        upall(session)

try:
    main()
except KeyboardInterrupt:
        print("\nGRM interrupted.")
        raise SystemExit(130)
