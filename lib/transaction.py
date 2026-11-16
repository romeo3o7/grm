import shutil
import random
from pathlib import Path
from lib.models import Package

def stagenew(packagedir : Path, tfilepath: Path, name):
    stagedir = packagedir.with_suffix(packagedir.suffix + ".stage")
    if stagedir.is_dir():
        shutil.rmtree(stagedir)

    stagedir.mkdir(parents=True, exist_ok=True)
    sfilepath = stagedir / name
    try:
        tfilepath.replace(sfilepath)
    except OSError:
        print("moving temp file to stage dir failed")
        stagedir.rmdir()
        return None

    return stagedir

def stageold(packagedir):
    oldpkgdir = None
    if packagedir.is_dir():
        rand = random.randint(10000, 99999)
        oldpkgdir = packagedir.with_name(f"{packagedir.name}.{rand}")
        packagedir.rename(oldpkgdir)

    return oldpkgdir

def deldir(dirpath: Path | None) -> bool:
    if dirpath is None:
        return True

    try:
        if dirpath.is_dir():
            shutil.rmtree(dirpath)

        return True

    except OSError as exc:
        print(f"Failed to delete {dirpath}: {exc}")
        return False

def restorepkg(oldpkgdir, packagedir):
    if oldpkgdir is None:
        return True

    if packagedir.exists() or packagedir.is_symlink():
        print(f"Previous Package preserved at: {oldpkgdir}")
        return False

    try:
        oldpkgdir.rename(packagedir)
        return True

    except OSError as exc:
        print(f"CRITICAL: rollback failed: {exc}")
        print(f"Previous Package preserved at: {oldpkgdir}")
        return False
