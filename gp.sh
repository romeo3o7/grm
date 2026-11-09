# General Purpose
printerr() {
	printf '%s\n' "$1" >&2
}

usage() {
	cat <<'EOF'
usage: grm <command> [args]

	list                 list installed packages and their versions
	install <url>        install the latest release of https://github.com/<owner>/<repo>
	up_all           check every package (in parallel), then update interactively
	up_one <name>    update one package ("tool" or "tool.owner")
	outdated             show which packages have a newer release, changes nothing
	link <name>          add another symlink for a binary inside a package
	remove <name>        remove a package and the symlinks that point into it

environment:
	GRM_PROGRAMS_DIR     where packages live      (default: ~/Programs)
	GRM_BIN_DIR          where symlinks are made  (default: ~/bin)
	GITHUB_TOKEN         optional, lifts the 60 requests/hour API limit
EOF
}

cleanup_install() {
	# An interrupt can land between "old version -> backup" and "new version -> place".
	# In that window the target is missing and the backup is the only copy: put it back.
	if [[ -n $oldpath && -n $swap_target && -d $oldpath && ! -e $swap_target && ! -L $swap_target ]]; then
		if mv -T -- "$oldpath" "$swap_target"; then
			oldpath=""
		else
			printerr "could not restore $swap_target, the previous version is kept in $oldpath"
		fi
	fi
	# $oldpath is deliberately never deleted here, only install_package may do that once the swap succeeded
	if [[ -n $temp ]]; then rm -rf -- "$temp"; temp=""; fi
	if [[ -n $newpath ]]; then rm -rf -- "$newpath"; newpath=""; fi
}

cleanup() {
	cleanup_install
	if [[ -n $api_tmp ]]; then rm -rf -- "$api_tmp"; api_tmp=""; fi
}

print_lines() {
	local cols half
	cols=$(tput cols 2>/dev/null) || cols=100
	half=$(( cols / 2 ))
	printf '%*s' "$half" '' | tr ' ' '='
	printf ']\n'
}

prompt_name() {
	# prompt_name [default] [program_path] -> prints a usable link name on stdout
	# program_path lets us accept an existing link that already points into the same package
	local default=${1:-} own=${2:-} reply target
	local valid='^[A-Za-z0-9_][A-Za-z0-9._-]*$'

	while true; do
		read -r -p "name for the link${default:+ [$default]} (q to cancel): " reply || return 1
		if [[ -z $reply ]]; then reply=$default; fi
		if [[ ${reply,,} == q ]]; then return 2
		fi
		if [[ ! $reply =~ $valid ]]; then
			printerr "not allowed"
			continue
		fi
		if (( ${#reply} > 64 )); then
			printerr "name too long"
			continue
		fi

		target="$bin_dir/$reply"
		if [[ -e $target || -L $target ]]; then
			if [[ -L $target && -n $own && $(readlink -- "$target") == "$own"/* ]]; then :
			else
				printerr "$target already exists"
				continue
			fi
		fi
		printf '%s\n' "$reply"
		return 0
	done
}

confirmation() {
	# confirmation "msg" "prompt"
	# returns 0 for yes, 2 for no,1 on EOF/error
	# call it as: if confirmation ...; then rc=0; else rc=$?; fi   (a bare call dies under set -e)
	local msg=$1 prompt=$2 reply
	if [[ -z $msg || -z $prompt ]]; then
		printerr "confirmation: empty msg or prompt"
		return 1
	fi
	printf '\n%s\n\n' "$msg" >&2

	while true; do
		if ! read -r -p "$prompt" reply; then
			printerr "confirmation: read"
			return 1
		fi
		case "${reply,,}" in
			y) return 0 ;;
			n) return 1 ;;
			*) printerr "Invalid choice" ;;
		esac
	done
}
