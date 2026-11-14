from pathlib import Path
from extract import extract
from remote import remfileinstall
from models import Package
from metadata import wmd
from gp import deldir
from ppath import (cachepath , sanpkgdir)
from transaction import (stagenew,stageold,restorepkg)

def installpkg(session, programsdir, pkg: Package, candidate, pkgversion, packagedir: Path | None = None):
    candname = candidate["name"]
    candsize = candidate["size"]
    candtype = candidate["content_type"]
    candurl = candidate["browser_download_url"]

    # cache path to install the remote file
    cpath = cachepath(programsdir)
    tfilepath = cpath / candname

    print(f"Installing... ")
    if not remfileinstall(session,candurl,tfilepath,candsize):
        return False

    filesize = tfilepath.stat().st_size
    if filesize != candsize:
        print(f"data lost, size of temp: {filesize}, size of installed file specifed by gh: {candsize}")
        tfilepath.unlink()
        return False

    # sanity check on package directory
    packagedir = sanpkgdir(pkg,programsdir,packagedir)

    # transaction
    stagedir = stagenew(packagedir, tfilepath, candname)

    if not stagedir:
        return False

    pkg.assetName = candname
    pkg.version = pkgversion

    oldpkgdir = None

    try:
        mdpath = stagedir / "metafile.grm"

        if not wmd(mdpath, pkg):
            return False

        stagedfilepath = stagedir / candname
        if extract(stagedfilepath,stagedir,candtype) is not None:
            stagedfilepath.unlink()

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
