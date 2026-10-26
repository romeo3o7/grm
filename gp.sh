# General Purpose
printerr() {
	printf '%s\n' "$1" >&2
}

usage() {
	printf '\tlist\t\t+{} List Availabe Package Names\n\tinstall\t\t+{url} Installs The Remote Repo\ngrm\tupdate_all\t+{} Updates All Registered Programs\n\tupdate_one\t+{package name} Updates The Package\n'
}

fetch_latest() {
	# called as: fetch_latest $owner $project
	local owner_in=$1
	local project_in=$2
	curl --connect-timeout 3 --max-time 10 --show-error -fsS "https://api.github.com/repos/$owner_in/$project_in/releases/latest"
}

cleanup() {
	if [[ -n $temp ]]; then rm -rf -- "$temp"; fi
	if [[ -n $newpath ]]; then rm -rf -- "$newpath"; fi
}
list_packages() {
	local metadatafile version dir
	for dir in "$programs_dir/"/*; do
		metadatafile=$(cat "$dir/metaGRUfile" 2>/dev/null) || continue
		version=$(grep '^Version:' <<< "$metadatafile" | sed 's|Version:||' | tr -d '\n') || continue
		printf '%s: %s\n' "${dir##*/}" "$version"
	done
}

print_lines(){
	local totalcol col i

	if ! totalcol=$(tput cols 2>/dev/null); then
		totalcol=100
	fi
	col=$(( $totalcol / 2 ))
	for (( i=0; i<=$col;i++ )); do
		printf '='
	done
	printf ']\n'
}
