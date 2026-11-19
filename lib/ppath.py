from lib.models import Package
from pathlib import Path
import sys

def malfile(name):
    if not name or name in (".", "..") or len(name.encode("utf-8")) > 255:
        return True

    if "/" in name or "\0" in name:
        return True

    return False

def sansupkg(pkg : Package, programsdir, spackagedir):
    apackagedir = programsdir / f"{pkg.owner}_{pkg.name}"
    if spackagedir is not None:
        if spackagedir == apackagedir:
            return spackagedir

    print("metadata information and directory mismatch.\nPossible malformed md file or Directory name was modifed")
    return None

def cachepath(programsdir):
    cachepath = programsdir / ".cache"
    cachepath.mkdir(parents=True,exist_ok=True)
    return cachepath

def getPpath():
    home = Path.home()
    match sys.platform:
        case "linux":
            return home / ".local"/ "grm"
        case "win32":
            return home / "AppData" / "Local" / "grm"
        case "darwin":
            return home / "Applications" / "grm"
        case _:
            return None

def rtpkgs():
    programsdir = getPpath()
    if not programsdir.is_dir():
        print("Programs location storage doesn't exit")
        return [],programsdir
    targetDir = []
    for packagedir in programsdir.iterdir():
        leftover = packagedir.suffix.lower() == ".stage" or packagedir.suffix.lower() == ".bak"
        if packagedir.is_dir() and not leftover and (packagedir / "metafile.grm").is_file():
            targetDir.append(packagedir)
    return sorted(targetDir) , programsdir
