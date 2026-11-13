from pathlib import Path
from remote import remfileinstall
from models import Package
from metadata import wmd
from helpers import deldir
from ppath import (cachepath , sanpkgdir)
from transaction import (stagenew,stageold,restorepkg)

def installpkg(session, candidate, pkg: Package, programsdir ,packagedir: Path | None = None):
    # cache path to install the remote file
    cpath = cachepath(programsdir)
    name = candidate["name"]
    candsize = candidate["size"]
    tfilepath = cpath / f"{name}"
    url = candidate["browser_download_url"]

    print(f"Installing... ")
    if not remfileinstall(session,url,tfilepath,candsize):
        return False

    filesize = tfilepath.stat().st_size
    if filesize != candsize:
        print(f"data lost, size of temp: {filesize}, size of installed file specifed by gh: {candsize}")
        tfilepath.unlink()
        return False

    # sanity check on package directory
    packagedir = sanpkgdir(pkg,programsdir,packagedir)

    # transaction
    stagedir = stagenew(packagedir, tfilepath, name)

    if not stagedir:
        return False

    oldpkgdir = None

    try:
        mdpath = stagedir / "metafile.grm"

        if not wmd(mdpath, pkg):
            return False

        oldpkgdir = stageold(packagedir)

        # the big move
        stagedir.rename(packagedir)

    except KeyboardInterrupt:
        if stagedir.exists():
            restorepkg(oldpkgdir, packagedir)
        raise

    except OSError as exc:
        print(f"Installation failed: {exc}")
        restorepkg(oldpkgdir, packagedir)
        return False

    finally: deldir(stagedir)

    if oldpkgdir is not None:
        deldir(oldpkgdir)

    print(f"DONE, {pkg.name} is Installed")
    return True
