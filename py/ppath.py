from pathlib import Path

def rtpkgs():
    home = Path.home()
    programsPath = home / "Programs"

    if not programsPath.is_dir():
        print("Programs location storage doesn't exit")
        return []
    targetDir = []
    for packagePath in programsPath.iterdir():
        if packagePath.is_dir() and (packagePath / "metaGRMfile").is_file():
            targetDir.append(packagePath)
    return targetDir
