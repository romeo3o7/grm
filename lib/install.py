from pathlib import Path
from lib.extract import extract
from lib.remote import gtlatest
from lib.candidate import selcand
from lib.gp import confirmation
from lib.models import Package
from lib.remote import remfileinstall
from lib.metadata import wmd
from lib.ppath import (cachepath,sansupkg)
from lib.transaction import (deldir,stagenew,stageold,restorepkg)

def installpkg(session, pkg: Package,programsdir, packagedir):
    url = f"https://api.github.com/repos/{pkg.owner}/{pkg.name}/releases/latest"
    resJson = gtlatest(session, url)
    if resJson is None:
        return False

    remoteVersion = resJson.get("tag_name")
    if not remoteVersion:
        print("could not get latest version")
        return False
    if pkg.version != "" and remoteVersion == pkg.version:
        return True

    if not confirmation(f"{pkg.name}: Latest Version Found: {remoteVersion}\nDo You Wish to Procced With The Installation?" , "[y/n/q]:"):
        return True

    candidate = selcand(resJson,pkg.assetName)
    if candidate is None:
        print("Couldn't find candidate")
        return False
    candname = candidate["name"]
    candsize = candidate["size"]
    candtype = candidate["content_type"]
    candurl = candidate["browser_download_url"]

    print("Installing... ")
    print(f"total size = {candsize // 1048576} MB")

    # cache path to install the remote file
    cpath = cachepath(programsdir)
    tfilepath = cpath / candname
    if not remfileinstall(session,candurl,tfilepath):
        return False
    filesize = tfilepath.stat().st_size
    if filesize != candsize:
        print(f"data lost, size of temp: {filesize}, size of installed file specifed by gh: {candsize}")
        tfilepath.unlink()
        return False

    # transaction .stage dir to move the installed file to
    stagedir = stagenew(packagedir, tfilepath, candname)
    if not stagedir:
        tfilepath.unlink()
        return False

    pkg.assetName = candname
    pkg.version = remoteVersion

    oldpkgdir = None

    try:
        stagedfilepath = stagedir / candname
        if extract(stagedfilepath,stagedir,candtype):
            stagedfilepath.unlink()

        mdpath = stagedir / "metafile.grm"
        wmd(mdpath, pkg)

        # if old pkg exist rename it to .bak, insuring packagedir doesn't exist
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
    finally:
        deldir(stagedir)

    if oldpkgdir is not None:
        deldir(oldpkgdir)

    print(f"DONE, {pkg.name} is Installed")
    return True
