from lib.gp import confirmation

# True delete False keep
def extract(filepath, dst , candtype):
    import tarfile
    import zipfile
    from zipfile import BadZipFile
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
        return not confirmation(f"Unkown Type: {candtype}\n Keep?", "[y/n]")
    except (EOFError, tarfile.TarError, BadZipFile) as err:
        print(f"Extraction failed: {err}")
        raise
