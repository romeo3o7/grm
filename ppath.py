import shutil
import random
from models import Package
from pathlib import Path

def mkpkgdir(pkg: Package):
    programsPath = getPpath()
    packagedir = programsPath / f"{pkg.name}.{pkg.owner}"
    packagedir.mkdir(parents=True, exist_ok=True)
    return packagedir

def cachepath(packagedir):
    cachepath = getPpath() / "cache"
    cachepath.mkdir(parents=True,exist_ok=True)
    return cachepath

def stageins(packagedir : Path, tfilepath: Path, name):
    stagedir = packagedir.with_suffix(packagedir.suffix + ".stage")
    if stagedir.is_dir():
        shutil.rmtree(stagedir)
    stagedir.mkdir(parents=True, exist_ok=True)
    sfilepath = stagedir / name
    tfilepath.replace(sfilepath)
    return stagedir

def actins(stagePath, name):
    packagedir = stagePath.with_suffix("")
    if packagedir.is_dir():
        rand = random.randint(10000, 99999)
        oldpkgdir = packagedir.with_name(f"{packagedir.name}.{rand}")
        packagedir.rename(oldpkgdir)
    stagePath.rename(packagedir)
    if oldpkgdir.is_dir():
        shutil.rmtree(oldpkgdir)
    return packagedir

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
    return targetDir
