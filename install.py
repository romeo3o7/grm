from pathlib import Path
from remote import remfileinstall
from models import Package
from metadata import wmd
from ppath import (cachepath , mkpkgdir)
from transaction import (stageins,actins)

def installpkg(session, candidate, pkg: Package, programsdir ,packagedir: Path | None = None):
    # if packages dir not supplied then infer one
    if not packagedir:
        packagedir = mkpkgdir(pkg,programsdir)

    cpath = cachepath(programsdir)
    name = candidate["name"]
    tfilepath = cpath / f"{name}"
    url = candidate["browser_download_url"]

    print(f"Installing... ")
    if not remfileinstall(session,url,tfilepath):
        return False

    filesize = tfilepath.stat().st_size
    if filesize != candidate["size"]:
        print(f"data lost, size of temp: {filesize}, size of installed file specifed by gh: {candidate["size"]}")
        tfilepath.unlink()
        return False

    # transaction
    stagedir = stageins(packagedir,tfilepath,name)
    if not stagedir:
        return False

    mdpath = stagedir / "metafile.grm"
    if not wmd(mdpath,pkg):
        return False

    savedPath = actins(stagedir,name)

    print(f"DONE, {pkg.name} is Installed")
    return True
