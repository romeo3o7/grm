import os
import requests
from ppath import (ctmpdir , mkpkgpath, stageins,actins)
from models import Package
from metadata import wmd

def inremote(session, candidate, pkg: Package, packagePath: Path | None = None):
    tpath = ctmpdir()
    name = candidate["name"]
    tfilepath = tpath / f"{name}"
    url = candidate["browser_download_url"]
    print(f"Installing -> {tpath}")
    with session.get(url, stream=True,timeout=10) as req:
        req.raise_for_status()
        with open(tfilepath,"wb") as f:
            for chunk in req.iter_content(chunk_size=512000):
                f.write(chunk)

    tmpsize = os.path.getsize(tfilepath)
    if tmpsize != candidate["size"]:
        print(f"data lost, size of temp: {tmpsize}, size of specifed by gh: {candidate["size"]}")
        return False

    if not packagePath:
        packagePath = mkpkgpath(pkg)
    # stage, move tfilepath to packagePath with .stage using shutil because across device linking
    stagedPath = stageins(packagePath,tfilepath,name)
    # actually move it to the path, stagedPath -> packagePath without .stage suffix, + name
    savedPath = actins(stagedPath,name)
    mdpath = savedPath / "metafile.grm"
    wmd(mdpath,pkg) 

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
