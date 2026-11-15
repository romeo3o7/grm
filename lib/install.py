from pathlib import Path
from lib.extract import extract
from lib.remote import gtlatest
from lib.candidate import selcand
from lib.gp import (confirmation,buildwall)
from lib.models import Package
from lib.remote import remfileinstall
from lib.metadata import wmd
from lib.gp import deldir
from lib.ppath import (cachepath , sanpkgdir)
from lib.transaction import (stagenew,stageold,restorepkg)

def installpkg(session, pkg: Package,programsdir, packagedir: Path | None = None):
    buildwall()
    url = f"https://api.github.com/repos/{pkg.owner}/{pkg.name}/releases/latest"
    print(f"{pkg.name}: Checking for latest version")

    resJson = gtlatest(session, url)
    if resJson is None:
        print(f"json failed for {pkg.name}")
        return False

    remoteVersion = resJson.get("tag_name")
    if not remoteVersion:
        print("could not get latest version")
        return False

    if pkg.version != "" and remoteVersion == pkg.version:
        print(f"{pkg.name} is up to date")
        return True

    if not confirmation(f"Version Found: {remoteVersion}\nDo You Wish to Procced With The Installation?" , "[y/n]:"):
        return True

    packagedir = sanpkgdir(pkg,programsdir,packagedir)

    candidate = selcand(resJson,pkg.assetName)
    if candidate is None:
        print("Couldn't find candidate")
        return False

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

    # transaction
    stagedir = stagenew(packagedir, tfilepath, candname)

    if not stagedir:
        return False

    pkg.assetName = candname
    pkg.version = remoteVersion

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
