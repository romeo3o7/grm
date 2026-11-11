from pathlib import Path
import tempfile
import shutil
import atexit

def getPpath():
    home = Path.home()
    programsPath = home / "Programs"
    return programsPath

def ctmpdir():
    tdir = tempfile.mkdtemp()
    atexit.register(shutil.rmtree, tdir, ignore_errors=True)
    return Path(tdir)

def rtpkgs():
    programsPath = getPpath()

    if not programsPath.is_dir():
        print("Programs location storage doesn't exit")
        return []
    targetDir = []
    for packagePath in programsPath.iterdir():
        if packagePath.is_dir() and (packagePath / "metaGRMfile").is_file():
            targetDir.append(packagePath)
    return targetDir
