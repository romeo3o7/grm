from pathlib import Path
from lib.metadata import rmd
from lib.ppath import (rtpkgs,getPpath,sanpkgdir)
from lib.remote import gtlatest
from lib.install import installpkg
from lib.candidate import selcand
from lib.gp import (confirmation,buildwall)
from lib.models import Package

def upall(session):
    tgPaths , programsdir = rtpkgs()
    for pkgdir in tgPaths:
        pkg = Package()
        mdfile = pkgdir / "metafile.grm"
        if not rmd(mdfile,pkg):
            continue
        if not installpkg(session,pkg,programsdir,pkgdir):
            continue

def pkgdownload(session,owner,pkgname):
    programsdir = getPpath()
    pkgdir = programsdir / f"{pkgname}.{owner}"
    if pkgdir.is_dir():
        print("Package already Exists")
        return False

    pkg = Package()
    pkg.name = pkgname
    pkg.owner = owner
    if not installpkg(session,pkg,programsdir,pkgdir):
        return False
