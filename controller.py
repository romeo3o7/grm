import os
import sys
import requests
from service import (upall,upone,pkgdownload)

def main():
    argsize = len(sys.argv)
    if argsize < 1:
        sys.exit(1)
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
            if argsize > 3:
                owner = sys.argv[2]
                pkgname = sys.argv[3]
                if not pkgdownload(session,owner,pkgname):
                    sys.exit(1)

        if cmd == "up_all":
            fails = upall(session)
            if fails == 0:
                sys.exit()

            print(f"{fails} Programs Failed To Update")
            sys.exit(1)

        if cmd == "up_one":
            if argsize > 3:
                owner = sys.argv[2]
                pkgname = sys.argv[3]
                if not upone(session,owner,pkgname):
                    sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        raise SystemExit("\nGRM interrupted.")
