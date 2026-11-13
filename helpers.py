import shutil

def deldir(dirpath: Path | None) -> bool:
    if dirpath is None:
        return True

    try:
        if dirpath.is_dir():
            shutil.rmtree(dirpath)

        return True

    except OSError as exc:
        print(f"Failed to delete {dirpath}: {exc}")
        return False

def confirmation(msg,prompt):
    while True:
        reply = input(f"{msg} - {prompt} ")
        reply = reply.strip().lower()
        if reply == 'y':
            return True
        if reply == 'n' or reply == 'q':
            return False
