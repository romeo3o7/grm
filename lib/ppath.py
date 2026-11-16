from lib.models import Package
from pathlib import Path

def sanpkgdir(pkg : Package, programsdir, spackagedir):
    apackagedir = programsdir / f"{pkg.name}.{pkg.owner}"
    if spackagedir is not None:
        # supplied vs Actual check
        if spackagedir == apackagedir:
            return spackagedir

    return None

def cachepath(programsdir):
    cachepath = programsdir / ".cache"
    cachepath.mkdir(parents=True,exist_ok=True)
    return cachepath

def getPpath():
    home = Path.home()
    programsdir = home / "Programs"
    return programsdir

def rtpkgs():
    programsdir = getPpath()
    if not programsdir.is_dir():
        print("Programs location storage doesn't exit")
        return [],programsdir
    targetDir = []
    for packagedir in programsdir.iterdir():
        leftover = packagedir.suffix.lower() != ".stage" and packagedir.suffix.lower() != ".bak"
        if packagedir.is_dir() and leftover and (packagedir / "metafile.grm").is_file():
            targetDir.append(packagedir)
    return sorted(targetDir) , programsdir
