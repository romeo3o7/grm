### GRM is Github Releases Assets Manager
### Flags:
| Left columns  | Right columns |
| ------------- |:-------------:|
| list          | +{} List Availabe Package Names      |
| install       | +{url} Installs The Remote Repo      |
| update_all    | +{} Updates All Registered Programs  |
| update_one    |  +{package name} Updates The Package |

install simply parses the url and queries github api for Availabe Assets

Flow of Asset selection goes likh this:
* read the asset name in metadata file, if it exists, and look for a match. if nothing is found
* positive filtering based on the architecture and os. if still nothing
* just list all available assets

>if more than one assets were found the user is prompted to select the type they want\
installation is followed then by an attempt of extraction.\
for unsupported types it is saved as is after a confirmation from the user\

After the installation, we create and write to the metadata file

Packages are stored in $HOME/Programs. stored as {packageName.packageOwner}\
inside each Directory a meta file is saved with the following structure(no space):

Owner:packageOwner\
Project:packageName\
Version:latestPackageVersion\
AssetName:AssetName

>That structure is then used to maintain the package.\
A missing meta file means it cannot be maintained.\
but creation of one is simple, as much as the structure is followed.

Flow of update_* is tiny bit different

with the use of the meatadata file, current and latest versions are compared\
and a mismatch triggers a remote fresh install. whilst also updating metadata file.
