import platform
from helpers import confirmation

def selcand(json):
    candidates = retcand(json)
    if not candidates:
        print("no candidates")
        return None
    for number, asset in enumerate(candidates,start=1):
        print(f"{number}.{asset['name']}")
    while True:
        reply = input("choose the desired asset name to install: ")
        if reply.isdigit():
            index = int(reply)
            if 1 <= index <= len(candidates):
                thechosenone = candidates[index-1]
                if confirmation(f"you have choosen: {thechosenone["name"]}, is that ok?" , "[y/n]:"):
                    break
    return thechosenone


def retcand(json):
    candidates = []
    patterns, ext = retpattern()

    for asset in json["assets"]:
        casset = asset["name"].lower()
        if casset.endswith(tuple(ext)):
            continue

        append = True
        for pattern in patterns:
            if pattern in casset.lower():
                append = False
                break
        if append:
            candidates.append(asset)
    return candidates

def retpattern():
    hos = platform.system().lower()
    harch = platform.machine().lower()
    ext = []
    patterns = []

    # os filtering
    if hos == "linux":
        ext.extend((
            ".msi" , ".dmg", ".ipa",
            ".pkg" , ".apk", ".exe",
            ".app"
        ))
        patterns.extend((
            "windows", "win32" , "win64",
            "darwin" , "macos" , "osx",
            "sha256" , "freebsd" , "netbsd",
        ))

    # arch filtering
    if harch in ("x86_64", "amd64", "x64"):
        patterns.extend((
            "aarch64", "arm64", "armv7", "armv6",
            "armhf", "i386", "i686", "386"
        ))
    return patterns , ext
