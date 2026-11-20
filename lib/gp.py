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

def buildwall(wallwidith):
    if wallwidith > 1 or wallwidith < 0:
        return None
    twindowsize = shutil.get_terminal_size()
    width = twindowsize.columns
    wall = width * wallwidith
    for i in range(int(wall)):
        print("-", end="")
    print()
