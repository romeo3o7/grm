from pathlib import Path
from lib.metadata import rmd
from lib.ppath import (rtpkgs,getPpath)
from lib.remote import (gtlatest,createGHsession)
from lib.install import installpkg
from lib.candidate import selcand
from lib.gp import (confirmation,buildwall)
from lib.models import Package
from lib.transaction import deldir

def pkgup(session,programsdir,pkgdir):
    pkg = Package()
    mdfile = pkgdir / "metafile.grm"
    try:
        if not rmd(mdfile,pkg):
            return False
        return installpkg(session,pkg,programsdir,pkgdir)
    except Exception as err:
        print(err)
        return False

def upall():
    print("Updating and loading repositories:")
    fails = 0
    tgPaths , programsdir = rtpkgs()
    with createGHsession() as session:
        for pkgdir in tgPaths:
            if not pkgup(session,programsdir,pkgdir):
                fails += 1
                continue
        return fails

def upone(owner,pkgname):
    programsdir = getPpath()
    pkgdir = programsdir / f"{owner}_{pkgname}"
    if not pkgdir.is_dir():
        print("Package Not Found, Use list to see installed Packages")
        return False
    print(f"Updating {pkgname}..")
    with createGHsession() as session:
        return pkgup(session,programsdir,pkgdir)

def listpkgs():
    tgPaths , programsdir = rtpkgs()
    for pkgdir in tgPaths:
        print(pkgdir.name)

def pkgremove(owner,pkgname):
    programsdir = getPpath()
    pkgdir = programsdir / f"{owner}_{pkgname}"
    if pkgdir.is_dir():
        return deldir(pkgdir)


def pkgdownload(owner,pkgname):
    programsdir = getPpath()
    pkgdir = programsdir / f"{owner}_{pkgname}"
    if pkgdir.is_dir():
        print("Package already Exists")
        return False
    pkg = Package()
    pkg.name = pkgname
    pkg.owner = owner
    with createGHsession() as session:
        return installpkg(session,pkg,programsdir,pkgdir)
