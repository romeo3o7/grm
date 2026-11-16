from pathlib import Path
from lib.metadata import rmd
from lib.ppath import (rtpkgs,getPpath,sanpkgdir)
from lib.remote import (gtlatest,createGHsession)
from lib.install import installpkg
from lib.candidate import selcand
from lib.gp import (confirmation,buildwall)
from lib.models import Package

def pkgup(session,programsdir,pkgdir):
    pkg = Package()
    mdfile = pkgdir / "metafile.grm"
    if not rmd(mdfile,pkg):
        return False
    if not installpkg(session,pkg,programsdir,pkgdir):
        return False

    return True

def upall():
    print("Updating and loading repositories:")
    with createGHsession() as session:
        fails = 0
        tgPaths , programsdir = rtpkgs()
        for pkgdir in tgPaths:
            if not pkgup(session,programsdir,pkgdir):
                fails += 1
                continue

        return fails

def upone(owner,pkgname):
    with createGHsession() as session:
        programsdir = getPpath()
        pkgdir = programsdir / f"{pkgname}.{owner}"
        if not pkgdir.is_dir():
            print("package Not Found\ngrm list to see installed Packages")
            return False

        if not pkgup(session,programsdir,pkgdir):
            return False

        return True

def listpkgs():
    tgPaths , programsdir = rtpkgs()
    for pkgdir in tgPaths:
        print(pkgdir.name)

def pkgdownload(owner,pkgname):
    with createGHsession() as session:
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

        return True

        print(pkgdir.name)
