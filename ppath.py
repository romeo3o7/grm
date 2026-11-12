from models import Package
from pathlib import Path
import tempfile
import shutil
import os
import atexit

def mkpkgpath(pkg: Package):
    programsPath = getPpath()
    pkgpath = programsPath / f"{pkg.name}.{pkg.owner}"
    pkgpath.mkdir(parents=True, exist_ok=True)
    return pkgpath

def stageins(pkgpath : Path, tfilepath: Path, name):
    stagedPath = pkgpath.with_suffix(pkgpath.suffix + ".stage")
    if stagedPath.is_dir():
        shutil.rmtree(stagedPath)
    stagedPath.mkdir(parents=True, exist_ok=True)
    sfilepath = stagedPath / name
    shutil.move(tfilepath, sfilepath)
    return stagedPath

def actins(stagePath, name):
    pkgpath = stagePath.with_suffix("")
    if pkgpath.is_dir():
        shutil.rmtree(pkgpath)
    pkgpath.mkdir(parents=True, exist_ok=True)
    os.replace(stagePath,pkgpath)
    return pkgpath

def getPpath():
    home = Path.home()
    programsPath = home / "Programs"
    return programsPath

def ctmpdir():
    tdir = tempfile.mkdtemp()
    atexit.register(shutil.rmtree, tdir, ignore_errors=True)
    return Path(tdir)

def rtpkgs():
    programsPath = getPpath()

    if not programsPath.is_dir():
        print("Programs location storage doesn't exit")
        return []
    targetDir = []
    for pkgpath in programsPath.iterdir():
        if pkgpath.is_dir() and (pkgpath / "metafile.grm").is_file():
            targetDir.append(pkgpath)
    return targetDir
