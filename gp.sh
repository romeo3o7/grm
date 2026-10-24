# General Purpose
printerr() {
	printf '\n%s\n' "$1" >&2
}

usage() {
printf 'install: +url, installs the remote repo\nupdate_all: update all Programs in %s\nupdate_one: update one package, directory name is required\n' "$programs_dir"
}

fetch_latest() {
	# called as: fetch_latest $owner $project
	local owner_in=$1
	local project_in=$2
	curl -fsS "https://api.github.com/repos/$owner_in/$project_in/releases/latest"
}
