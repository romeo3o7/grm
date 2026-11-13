from models import Package
from pathlib import Path

def mkpkgdir(pkg: Package,programsdir):
    programsPath = programsdir
    packagedir = programsPath / f"{pkg.name}.{pkg.owner}"
    packagedir.mkdir(parents=True, exist_ok=True)
    return packagedir

def cachepath(programsdir):
    cachepath = programsdir / "cache"
    cachepath.mkdir(parents=True,exist_ok=True)
    return cachepath

def getPpath():
    home = Path.home()
    programsPath = home / "Programs"
    return programsPath

def rtpkgs():
    programsPath = getPpath()
    if not programsPath.is_dir():
        print("Programs location storage doesn't exit")
        return []
    targetDir = []
    for packagedir in programsPath.iterdir():
        if packagedir.is_dir() and (packagedir / "metafile.grm").is_file():
            targetDir.append(packagedir)
    return targetDir , programsPath
