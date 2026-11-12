from pathlib import Path
from ppath import (cachepath , mkpkgdir, stageins,actins)
from remote import remfileinstall
from models import Package
from metadata import wmd

def installpkg(session, candidate, pkg: Package, packagedir: Path | None = None):
    # if packages dir not supplied then infer one
    if not packagedir:
        packagedir = mkpkgdir(pkg)

    cpath = cachepath(packagedir)
    name = candidate["name"]
    tfilepath = cpath / f"{name}"
    url = candidate["browser_download_url"]

    print(f"Installing... ")
    remfileinstall(session,url,tfilepath)

    filesize = tfilepath.stat().st_size
    if filesize != candidate["size"]:
        print(f"data lost, size of temp: {filesize}, size of installed file specifed by gh: {candidate["size"]}")
        tfilepath.unlink()
        return False


    # stage, move tfilepath to packagedir with .stage
    stagedir = stageins(packagedir,tfilepath,name)
    # write metadata file
    mdpath = stagedir / "metafile.grm"
    wmd(mdpath,pkg)
    # install
    savedPath = actins(stagedir,name)

    print(f"DONE, {pkg.name} is Installed")
    return True
