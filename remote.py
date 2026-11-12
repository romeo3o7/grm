import os
import requests
from pathlib import Path
from ppath import (cstagedir , mkpkgdir, stageins,actins)
from models import Package
from metadata import wmd

def inremote(session, candidate, pkg: Package, packagedir: Path | None = None):
    tpath = cstagedir()
    name = candidate["name"]
    tfilepath = tpath / f"{name}"
    url = candidate["browser_download_url"]
    print(f"Installing -> {tpath}")
    with session.get(url, stream=True,timeout=10) as req:
        req.raise_for_status()
        with open(tfilepath,"wb") as f:
            for chunk in req.iter_content(chunk_size=512000):
                f.write(chunk)

    filesize = os.path.getsize(tfilepath)
    if filesize != candidate["size"]:
        print(f"data lost, size of temp: {filesize}, size of specifed by gh: {candidate["size"]}")
        tfilepath.unlink()
        return False

    # if packages dir not supplied then infer one
    if not packagedir:
        packagedir = mkpkgdir(pkg)

    # stage, move tfilepath to packagedir with .stage
    stagedir = stageins(packagedir,tfilepath,name)
    # write metadata file
    mdpath = stagedir / "metafile.grm"
    wmd(mdpath,pkg)
    # install
    savedPath = actins(stagedir,name)

    print("DONE, Package is Installed")
    return True

def gtlatest(session,pkg):
    url = f"https://api.github.com/repos/{pkg.owner}/{pkg.name}/releases/latest"
    print(f"{pkg.name}: Querying for latest release; current : {pkg.version}")
    try:
        res = session.get(url,timeout=5)
        res.raise_for_status()
        resJson = res.json()
        return resJson
    except requests.exceptions.JSONDecodeError as e:
        print(f"Invalid JSON response: {e}")
        return None
    except requests.exceptions.RequestException as e:
        print(f"The request failed: {e}")
        return None
