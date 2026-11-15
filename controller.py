import sys
from service import (listpkgs,upall,upone,pkgdownload)

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
            if not pkgdownload(owner,pkgname):
                sys.exit(1)

    elif cmd == "up_all":
        fails = upall()
        if fails == 0:
            sys.exit()

        print(f"{fails} Programs Failed To Update")
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
