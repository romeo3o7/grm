#!/usr/bin/env python3
import os
from dataclasses import dataclass
from pathlib import Path

@dataclass
class Package:
    packageName : str = ""
    owner       : str = ""
    version     : str = ""
    assetName   : str = ""
    link        : str = ""

def getProgramsDir():
    home = Path.home()
    programsPath = home / "Programs"

    if not programsPath.exists():
        print("Programs location storage doesn't exit")
        return 1
    targetDir = []
    for packagePath in programsPath.iterdir():
        if packagePath.is_dir() and (packagePath / "metaGRMfile").is_file():
            targetDir.append(packagePath)
    return targetDir

def readMetaData(rootdir,p):
    filepath = f"{rootdir}/metaGRMfile"
    with open(filepath,"r",encoding="utf-8") as file:
        for line in file:
            line = line.strip()
            key, value = line.split(':', 1)
            if key == "Owner":
                p.owner = value
            elif key == "Project":
                p.packageName = value
            elif key == "Version":
                p.version = value
            elif key == "AssetName":
                p.assetName = value
            elif key == "Link":
                p.link = value
def main():
    targetPaths = getProgramsDir()
    for path in targetPaths:
        print(path)

if __name__ == "__main__":
    main()
