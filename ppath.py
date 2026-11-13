from models import Package
from pathlib import Path

def sanpkgdir(pkg : Package, programsdir, spackagedir):
    apackagedir = programsdir / f"{pkg.name}.{pkg.owner}"
    if spackagedir is not None:
        # supplied vs Actual check
        if spackagedir == apackagedir:
            return spackagedir

    return apackagedir

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
        if packagedir.is_dir() and (packagedir / "metafile.grm").is_file():
            targetDir.append(packagedir)
    return targetDir , programsdir
