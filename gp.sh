# General Purpose
printerr() {
	printf '%s\n' "$1" >&2
}

usage() {
	printf '\tlist\t\t+{} List Availabe Package Names\n\tinstall\t\t+{url} Installs The Remote Repo\ngrm\tupdate_all\t+{} Updates All Registered Programs\n\tupdate_one\t+{package name} Updates The Package\n'
}

cleanup() {
	if [[ -n $temp ]]; then rm -rf -- "$temp"; fi
	if [[ -n $newpath ]]; then rm -rf -- "$newpath"; fi
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

prompt_name() {
	local reply
	local valid='^[A-Za-z0-9_][A-Za-z0-9._-]*$'

	while true; do
		read -r -p "name for the link (q to cancel): " reply || return 1
		if [[ ${reply,,} == q ]]; then return 2
		fi
		if [[ ! $reply =~ $valid ]]; then
			printerr "not allowed";
			continue
		fi
		if (( ${#reply} >= 10 )); then
			printerr "name too long";
			continue
		fi
		printf '%s\n' "$reply"
		return 0
	done
}

confirmation() {
	# confirmation "msg" "prompt"
	# best called inside a loop, and case $? 0) break 2) contiune *) return 1
	local msg=$1 prompt=$2 reply
	if [[ -z $msg && -z $prompt ]]; then return 1
	fi
	printf '\n%s\n\n' "$msg" >&2

	while true; do
		read -r -p "$prompt" reply || return 1
		case "${reply,,}" in
			y)   return 0 ;;
			n|q) return 2 ;;
			*)   printerr "Invalid choice" ;;
		esac
	done
}
