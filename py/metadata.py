def rdmeta(rootdir, p : Package):
    # rootdir must be a path object And the caller make sure metaGRMfile exists
    filepath = rootdir / "metaGRMfile"

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
            elif key == "Project":
                p.name = value
            elif key == "Version":
                p.version = value
            elif key == "AssetName":
                p.assetName = value
            elif key == "Link":
                p.link = value

    if not p.owner or not p.version or not p.name:
        print("rdmeta: Important fields are not found")
        return None

    return p
