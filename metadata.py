from models import Package

def wmd(filePath,pkg : Package):
    # make sure pkg fields are updated
    with open(filePath,"w",encoding="utf-8") as file:
        file.write(f"Package:{pkg.name}\n")
        file.write(f"Owner:{pkg.owner}\n")
        file.write(f"Version:{pkg.version}\n")
        file.write(f"AssetName:{pkg.assetName}\n")
        file.write(f"Link:{pkg.name}\n")


def rmd(filepath, p : Package):
    cn = 0
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

    if not p.owner or not p.version or not p.name:
        print(f"rdmeta: Important fields are not found\nProblematic file {filepath}")
        return False
    if cn > 5:
        print(f"duplicit key, please resolve it\nProblematic file {filepath}")
        return False

    return True
