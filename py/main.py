import os
import requests
from dataclasses import dataclass
from pathlib import Path

@dataclass
class Package:
    name        : str = ""
    owner       : str = ""
    version     : str = ""
    assetName   : str = ""
    link        : str = ""

def gtlatest(session,pkg):
    url = f"https://api.github.com/repos/{pkg.owner}/{pkg.name}/releases/latest"
    print(f"quering for {pkg.name} latest release; current : {pkg.version}")
    try:
        res = session.get(url,timeout=5)
        res.raise_for_status()
        resJson = res.json()
        return resJson
    except requests.exceptions.RequestException as e:
        print(f"The request failed: {e}")
        return None

def rtpkgs():
    home = Path.home()
    programsPath = home / "Programs"

    if not programsPath.exists():
        print("Programs location storage doesn't exit")
        return []
    targetDir = []
    for packagePath in programsPath.iterdir():
        if packagePath.is_dir() and (packagePath / "metaGRMfile").is_file():
            targetDir.append(packagePath)
    return targetDir

def rdmeta(rootdir):
    # rootdir must be a path object And the caller make sure metaGRMfile exists
    filepath = rootdir / "metaGRMfile"

    p = Package()
    with open(filepath, "r", encoding="utf-8") as file:
        for line in file:
            line = line.strip()
            if ":" not in line:
                continue

            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip()

            if key == "Owner":
                p.owner = value
            elif key == "Project":
                p.name = value
            elif key == "Version":
                p.version = value
            elif key == "AssetName":
                p.assetName = value
            elif key == "Link":
                p.link = value

    if not p.owner or not p.version or not p.name:
        print("rdmeta: Important fields are not found")
        return None

    return p

def up_all():
    with requests.Session() as session:
        session.headers.update({
            "User-Agent": "grm/1.0",
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}"
        })
        tgPaths = rtpkgs()
        for path in tgPaths:
            pkg = rdmeta(path)
            if pkg is None:
                continue

            resJson = gtlatest(session, pkg)
            if resJson is None:
                print(f"json failed for {pkg.name}")
                continue

            remoteVersion = resJson.get("tag_name")
            if remoteVersion == pkg.version:
                print(f"{pkg.name} is up to date")
            else:
                print(f"new release is found : {remoteVersion}")
if __name__ == "__main__":
    up_all()
