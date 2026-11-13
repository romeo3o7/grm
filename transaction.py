import shutil
import random
from models import Package
from pathlib import Path

def stageins(packagedir : Path, tfilepath: Path, name):
    stagedir = packagedir.with_suffix(packagedir.suffix + ".stage")
    if stagedir.is_dir():
        shutil.rmtree(stagedir)

    stagedir.mkdir(parents=True, exist_ok=True)
    sfilepath = stagedir / name
    try:
        tfilepath.replace(sfilepath)
    except:
        print("moving temp file to stage dir failed")
        stagedir.rmdir()
        return None

    return stagedir

def actins(stagePath, name):
    oldpkgdir = None
    packagedir = stagePath.with_suffix("")
    if packagedir.is_dir():
        rand = random.randint(10000, 99999)
        oldpkgdir = packagedir.with_name(f"{packagedir.name}.{rand}")
        packagedir.rename(oldpkgdir)

    try:
        stagePath.rename(packagedir)
    except:
        print("installation failed")
        if oldpkgdir is not None:
            print(f"reversing the transaction\n{oldpkgdir} -> {packagedir}")
            oldpkgdir.rename(packagedir)
        return None

    if oldpkgdir is not None:
        shutil.rmtree(oldpkgdir)
    return packagedir
