import platform

def retcand(json):
    candidates = []
    patterns = retpattern()
    if not patterns:
        print("unsupported host")
        return []

    for asset in json["assets"]:
        append = True
        for pattern in patterns:
            if pattern in asset["name"].lower():
                append = False
                break
        if append:
            candidates.append(asset)
            print(f"adding to the candidates {asset["name"]}")
    return candidates

def retpattern():
    hos = platform.system().lower()
    harch = platform.machine().lower()
    patterns = []

    # os filtering
    if hos == "linux":
        patterns.extend((
            "windows", "win32", "win64",
            "darwin", "macos", "osx",
            ".exe", ".msi" , ".dmg"
        ))

    # arch filtering
    if harch in ("x86_64", "amd64", "x64"):
        patterns.extend((
            "aarch64", "arm64", "armv7", "armv6",
            "armhf", "i386", "i686"
        ))
    return patterns
