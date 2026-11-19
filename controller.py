import sys
from service import (listpkgs,upall,upone,pkgdownload,pkgremove)

def main():
    argsize = len(sys.argv)
    if argsize < 2:
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "list":
        listpkgs()

    elif cmd == "install":
        if argsize > 3:
            owner = sys.argv[2]
            pkgname = sys.argv[3]
            if pkgdownload(owner,pkgname):
                sys.exit(1)

    elif cmd == "remove":
        if argsize > 3:
            owner = sys.argv[2]
            pkgname = sys.argv[3]
            if not pkgremove(owner,pkgname):
                sys.exit(1)
            print("Deleted.")

    elif cmd == "up_all":
        if upall():
            sys.exit()
        sys.exit(1)

    elif cmd == "up_one":
        if argsize > 3:
            owner = sys.argv[2]
            pkgname = sys.argv[3]
            if not upone(owner,pkgname):
                sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        raise SystemExit("\nGRM interrupted.")
