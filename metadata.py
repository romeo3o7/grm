from models import Package

def wmd(fpath,pkg : Package):
    # make sure pkg fields are updated
    try:
        with open(fpath,"w",encoding="utf-8") as file:
            file.write(f"Package:{pkg.name}\n")
            file.write(f"Owner:{pkg.owner}\n")
            file.write(f"Version:{pkg.version}\n")
            file.write(f"AssetName:{pkg.assetName}\n")
            file.write(f"Link:{pkg.name}\n")
    except:
        print(f"failed to write to metadata file -> {fpath}")
        return False

    return True


def rmd(fpath, p : Package):
    cn = 0
    try:
        with open(fpath, "r", encoding="utf-8") as file:
            for line in file:
                line = line.strip()
                if ":" not in line:
                    continue

                key, value = line.split(':', 1)
                key = key.strip()
                value = value.strip()
                if key == "Owner":
                    p.owner = value
                    cn += 1
                elif key == "Package":
                    p.name = value
                    cn += 1
                elif key == "Version":
                    p.version = value
                    cn += 1
                elif key == "AssetName":
                    p.assetName = value
                    cn += 1
                elif key == "Link":
                    p.link = value
                    cn += 1
    except:
        print(f"failed to read metadata file -> {fpath}")
        return False

    if not p.owner or not p.version or not p.name:
        print(f"Important fields are not found\nProblematic file {fpath}")
        return False

    if cn > 5:
        print(f"duplicit key, please resolve it\nProblematic file {fpath}")
        return False

    return True
