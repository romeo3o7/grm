from dataclasses import dataclass

@dataclass
class Package:
    name        : str = ""
    owner       : str = ""
    version     : str = ""
    assetName   : str = ""
    link        : str = ""
