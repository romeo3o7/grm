from dataclasses import dataclass
from enum import Enum

@dataclass
class Package:
    name        : str = ""
    owner       : str = ""
    version     : str = ""
    assetName   : str = ""
    link        : str = ""

class InstallStatus(Enum):
    IN   = 0
    FAIL = 1
    UTD  = 2 
    SKIP = 3
