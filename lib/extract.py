import tarfile
import zipfile
from zipfile import BadZipFile
from lib.gp import confirmation

# True delete False keep
def extract(filepath, dst , candtype):
    if not filepath.is_file():
        return False

    try:
        if tarfile.is_tarfile(filepath):
            with tarfile.open(filepath, "r:*") as archive:
                archive.extractall(dst, filter="data")
            return True

        elif zipfile.is_zipfile(filepath):
            with zipfile.ZipFile(filepath) as archive:
                archive.extractall(dst)
            return True

    except (EOFError, tarfile.TarError, BadZipFile) as err:
        print(f"Extraction failed: {err}")
        return True

    if confirmation(f"Unkown Type: {candtype}\n Keep?", "[y/n]"):
        return False

    return True
