from pathlib import Path
from lib.metadata import rmd
from lib.ppath import (rtpkgs,getPpath,sansupkg)
from lib.remote import (gtlatest,createGHsession)
from lib.install import installpkg
from lib.candidate import selcand
from lib.gp import (confirmation,buildwall)
from lib.models import Package,InstallStatus
from lib.transaction import deldir

def pkgup(session,programsdir,pkgdir):
    pkg = Package()
    mdfile = pkgdir / "metafile.grm"
    try:
        if not rmd(mdfile,pkg) or not sansupkg(pkg,programsdir,pkgdir):
            print(f"Path: {pkgdir}")
            return InstallStatus.FAIL
        return installpkg(session,pkg,programsdir,pkgdir)
    except Exception as err:
        print(err)
        return InstallStatus.FAIL

def upall():
    print("Updating and loading repositories:")
    tgPaths , programsdir = rtpkgs()
    updated = failed = utd = skip = 0
    with createGHsession() as session:
        for pkgdir in tgPaths:
            status = pkgup(session,programsdir,pkgdir)
            match status:
                case InstallStatus.IN:
                    updated += 1
                case InstallStatus.FAIL:
                    failed += 1
                case InstallStatus.UTD:
                    utd += 1
                case InstallStatus.SKIP:
                    skip += 1

    print()
    if updated > 0:
        print(f"{updated} Program/s were updated")
    if utd > 0:
        print(f"{utd}/{len(tgPaths)} Programs are up to date")
    if skip > 0 :
        print(f"{skip} Program/s were skipped by the user")
    if failed > 0:
        print(f"{failed} Program/s Failed")
        return False

    return True

def upone(owner,pkgname):
    programsdir = getPpath()
    pkgdir = programsdir / f"{owner}_{pkgname}"
    if not pkgdir.is_dir():
        print("Package Not Found, Use list to see installed Packages")
        return False
    print(f"Updating {pkgname}..")
    with createGHsession() as session:
        status = pkgup(session,programsdir,pkgdir)

    match status:
        case InstallStatus.IN:
            print("Program is updated")
        case InstallStatus.FAIL:
            print("Program Failed to update")
            return 1
        case InstallStatus.UTD:
            print("Program Up to date")
        case InstallStatus.SKIP:
            print("You skipped, why?")

    return 0

def listpkgs():
    tgPaths , programsdir = rtpkgs()
    print(f"Packages = {len(tgPaths)}")
    buildwall(0.50)
    for pkgdir in tgPaths:
        pkg = Package()
        mdfile = pkgdir / "metafile.grm"
        try:
            if not rmd(mdfile,pkg) or not sansupkg(pkg,programsdir,pkgdir):
                print(f"Path = {pkgdir}, ", end="")
                print("STATUS = BAD")
                continue

            print(f"Package = {pkg.name}, ", end="")
            print("STATUS = GOOD, ",end="" )
            print(f"Version = {pkg.version}, " , end="")
            print(f"Direcoty = {pkgdir.name}")

        except OSError as err:
            print(f"wmd: {err}")

        finally: buildwall(0.75)


def pkgremove(owner,pkgname):
    programsdir = getPpath()
    pkgdir = programsdir / f"{owner}_{pkgname}"
    if not pkgdir.is_dir():
        print("Package not found")
        return False
    if deldir(pkgdir):
        print("Deleted")
        return True
    return False


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
         status = installpkg(session,pkg,programsdir,pkgdir)

    match status:
        case InstallStatus.IN:
            print("Program is installed")
        case InstallStatus.FAIL:
            print("Failed to install")
            return 1
        case InstallStatus.SKIP:
            print("You skipped, why?")

    return 0
