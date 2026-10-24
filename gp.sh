# General Purpose
printerr() {
	printf '%s\n' "$1" >&2
}

usage() {
	printf '\tlist\t\t+{} list packages\n\tinstall\t\t+{url} installs the remote repo\ngrm\tupdate_all\t+{} updates all registered Programs\n\tupdate_one\t+{package name} updates that one package\n'
}

fetch_latest() {
	# called as: fetch_latest $owner $project
	local owner_in=$1
	local project_in=$2
	curl -fsS "https://api.github.com/repos/$owner_in/$project_in/releases/latest"
}

list_packages() {
	local version
	for dir in "$programs_dir/"/*; do
		metadatafile=$(cat "$dir/metaGRUfile" 2>/dev/null) || continue
		version=$(grep '^Version:' <<< "$metadatafile" | sed 's|Version:||' | tr -d ' \r\n') || return 1
		printf '%s: %s\n' "${dir##*/}" "$version"
	done
}
