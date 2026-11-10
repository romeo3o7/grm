import os
import requests
from dataclasses import dataclass
from pathlib import Path
from metadata import rdmeta
from remote import gtlatest

@dataclass
class Package:
    name        : str = ""
    owner       : str = ""
    version     : str = ""
    assetName   : str = ""
    link        : str = ""

def confirmation(msg,prompt):
    print(msg)
    while True:
        reply = input(prompt )
        if len(reply) == 1:
            if reply == 'y':
                return 1
            if reply == 'n':
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


def up_all():
    with requests.Session() as session:
        session.headers.update({
            "User-Agent": "grm/1.0",
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}"
        })
        tgPaths = rtpkgs()
        for path in tgPaths:
            pkg = Package()
            rdmeta(path,pkg)
            if pkg is None:
                continue

            resJson = gtlatest(session, pkg)
            if resJson is None:
                print(f"json failed for {pkg.name}")
                continue

            remoteVersion = resJson.get("tag_name")
            if remoteVersion == pkg.version:
                print(f"{pkg.name} is up to date")
                continue
            print(f"new release is found : {remoteVersion}")
            if confirmation("do you wish to update?" , "[y/n]:"):
                print("updating")

if __name__ == "__main__":
    up_all()
