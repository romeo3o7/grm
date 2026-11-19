import shutil
from pathlib import Path

def confirmation(msg,prompt):
    while True:
        reply = input(f"{msg} - {prompt} ")
        reply = reply.strip().lower()
        if reply == 'y':
            return True
        if reply == 'n':
            return False
        if reply == 'q':
            raise SystemExit()

def buildwall(wallwidith):
    if wallwidith > 1 and wallwidith < 0:
        return None
    twindowsize = shutil.get_terminal_size()
    width = twindowsize.columns
    wall = width * wallwidith
    for i in range(int(wall)):
        print("-", end="")
    print()
