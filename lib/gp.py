import shutil
from pathlib import Path

def confirmation(msg,prompt):
    while True:
        reply = input(f"{msg} - {prompt} ")
        reply = reply.strip().lower()
        if reply == 'y':
            return True
        if reply == 'n' or reply == 'q':
            return False
def buildwall():
    twindowsize = shutil.get_terminal_size()
    width = twindowsize.columns

    wall = width // 2

    for i in range(wall):
        print("-", end="")

    print("|")
