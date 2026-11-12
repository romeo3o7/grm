from models import Package

def wmd(filePath,pkg : Package):
    # make sure pkg fields are updated
    with open(filePath,"w",encoding="utf-8") as file:
        file.write(f"Package:{pkg.name}\n")
        file.write(f"Owner:{pkg.owner}\n")
        file.write(f"Version:{pkg.version}\n")
        file.write(f"AssetName:{pkg.assetName}\n")
        file.write(f"Link:{pkg.name}\n")


def rmd(rootdir, p : Package):
    filepath = rootdir / "metafile.grm"

    with open(filepath, "r", encoding="utf-8") as file:
        for line in file:
            line = line.strip()
            if ":" not in line:
                continue

            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip()

            if key == "Owner":
                p.owner = value
            elif key == "Package":
                p.name = value
            elif key == "Version":
                p.version = value
            elif key == "AssetName":
                p.assetName = value
            elif key == "Link":
                p.link = value

    if not p.owner or not p.version or not p.name:
        print("rdmeta: Important fields are not found")
        return False

    return True

