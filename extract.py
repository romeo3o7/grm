import tarfile
import zipfile

def extract(filepath, dst , candtype):
    if not filepath.is_file():
        return None

    if tarfile.is_tarfile(filepath):
        with tarfile.open(filepath, "r:*") as archive:
            archive.extractall(dst, filter="data")
        return "tar"

    elif zipfile.is_zipfile(filepath):
        with zipfile.ZipFile(filepath) as archive:
            archive.extractall(dst)
        return "zip"

    print(f"Unkown type: {candtype}")
    return None
