import shutil
import os
import requests
from ppath import (ctmpdir , getPpath)
from models import Package

def inremote(session,candidate,pkg: Package):
    tpath = ctmpdir()
    name = candidate["name"]
    installtmp = tpath / f"{name}"
    url = candidate["browser_download_url"]
    print(f"Installing to {installtmp}")
    with session.get(url, stream=True) as req:
        req.raise_for_status()
        with open(installtmp,"wb") as f:
            for chunk in req.iter_content(chunk_size=512000):
                f.write(chunk)
    tmpsize = os.path.getsize(installtmp)
    if tmpsize != candidate["size"]:
        print(f"data lost, size of temp: {tmpsize}, size of specifed by gh: {candidate["size"]}")
        return None
    programsPath = getPpath()
    installPath = programsPath / "test" / f"{pkg.name}.{pkg.owner}"
    installPath.mkdir(parents=True, exist_ok=True)
    shutil.move(installtmp, installPath / name)

def gtlatest(session,pkg):
    url = f"https://api.github.com/repos/{pkg.owner}/{pkg.name}/releases/latest"
    print(f"Querying for {pkg.name} latest release; current : {pkg.version}")
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
