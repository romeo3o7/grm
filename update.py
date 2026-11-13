from metadata import rmd
from ppath import rtpkgs
from remote import gtlatest
from install import installpkg
from candidate import selcand
from helpers import confirmation
from models import Package

def upall(session):
    tgPaths , programsdir = rtpkgs()
    for pkgdir in tgPaths:
        pkg = Package()
        mdfile = pkgdir / "metafile.grm"
        if not rmd(mdfile,pkg):
            print("grm file protocol broken, not updating the package")
            continue

        resJson = gtlatest(session, pkg)
        if resJson is None:
            print(f"json failed for {pkg.name}")
            continue

        remoteVersion = resJson.get("tag_name")
        if not remoteVersion:
            print("could not get latest version")
            continue
        if remoteVersion == pkg.version:
            print(f"{pkg.name} is up to date")
            continue

        pkg.version = remoteVersion
        print(f"new release is found : {pkg.version}")
        if confirmation("do you wish to update?" , "[y/n]:"):
            candidate = selcand(resJson,pkg.assetName)
            if candidate is None:
                print("Couldn't find candidate")
                continue

            pkg.assetName = candidate["name"]
            if not installpkg(session,candidate,pkg,programsdir,pkgdir):
                continue
