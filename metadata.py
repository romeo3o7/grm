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
    seen = set()
    grmfileErr = False
    try:
        with open(fpath, "r", encoding="utf-8") as file:
            for line in file:
                line = line.strip()
                if ":" not in line:
                    continue

                key, value = line.split(':', 1)
                key = key.strip()
                value = value.strip()
                match key:
                    case "Owner":
                        if key in seen:
                            print("duplicate key")
                            grmfileErr=True
                            break
                        else:
                            p.owner = value
                            seen.add(key)

                    case "Package":
                        if key in seen:
                            print("duplicate key")
                            grmfileErr=True
                            break
                        else:
                            p.name = value
                            seen.add(key)

                    case "Version":
                        if key in seen:
                            print("duplicate key")
                            grmfileErr=True
                            break
                        else:
                            p.version = value
                            seen.add(key)

                    case "AssetName":
                        if key in seen:
                            print("duplicate key")
                            grmfileErr=True
                            break
                        else:
                            p.assetName = value
                            seen.add(key)

                    case "Link":
                        if key in seen:
                            print("duplicate key")
                            grmfileErr=True
                            break
                        else:
                            p.link = value
                            seen.add(key)
                    case _:
                        print("unknow key")
                        grmfileErr = True
                        break


    except:
        print(f"failed to read metadata file -> {fpath}")
        return False

    if not p.owner or not p.version or not p.name:
        print(f"Important Fields are Missing")
        grmfileErr = True

    if grmfileErr == True:
        print(f"GRM file protocol broken\nProblematic file {fpath}")
        return False

    return True
