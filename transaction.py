import shutil
import random
from models import Package
from pathlib import Path
from gp import deldir

def stagenew(packagedir : Path, tfilepath: Path, name):
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

def stageold(packagedir):
    oldpkgdir = None
    if packagedir.is_dir():
        rand = random.randint(10000, 99999)
        oldpkgdir = packagedir.with_name(f"{packagedir.name}.{rand}")
        packagedir.rename(oldpkgdir)

    return oldpkgdir

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
