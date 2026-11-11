import os
import requests
from metadata import rmd
from ppath import rtpkgs
from remote import gtlatest
from candidate import selcand
from helpers import confirmation
from models import Package

def up_all():
    ghtoken = os.getenv("GITHUB_TOKEN", "").strip()
    headers = {
            "User-Agent": "grm/1.0",
            "Accept": "application/vnd.github+json",
            **({"Authorization": f"Bearer {ghtoken}"} if ghtoken else {})
        }
    with requests.Session() as session:
        session.headers.update(headers)
        tgPaths = rtpkgs()
        for path in tgPaths:
            pkg = Package()
            if not rmd(path,pkg):
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
            print(f"new release is found : {remoteVersion}")
            if confirmation("do you wish to update?" , "[y/n]:"):
                candidate = selcand(resJson)
                if candidate is None:
                    print("Couldn't find candidate")
                    continue
                print(f"updating {candidate["name"]} by downloading from {candidate["browser_download_url"]}")

if __name__ == "__main__":
    up_all()
