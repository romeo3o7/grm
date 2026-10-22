# General Purpose
printerr() {
	printf '\n%s\n' "$1" >&2
}

usage() {
printf 'install: +url, installs the remote repo\nupdate_all: update all Programs in %s\nupdate_one: update one package, directory name is required\n' "$programs_dir"
}
