import tarfile
import zipfile

def extract(filepath, dst , candtype):
    if not filepath.is_file():
        return None

    try:
        if tarfile.is_tarfile(filepath):
            with tarfile.open(filepath, "r:*") as archive:
                archive.extractall(dst, filter="data")
            return "tar"

        elif zipfile.is_zipfile(filepath):
            with zipfile.ZipFile(filepath) as archive:
                archive.extractall(dst)
            return "zip"

        if confirmation(f"Unkown Type: {candtype}\n Keep?", "[y/n]"):
            return "keep"
    except (EOFError, tarfile.TarError, BadZipFile) as err:
        print(f"Extraction failed: {err}")
        return None

    return None
