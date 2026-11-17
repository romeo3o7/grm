#!/usr/bin/env bash
usage() {
	cat <<'EOF'
usage: grm <command> [args]
	list                 list installed packages and their versions
	in|install           install the latest release of <owner>/<repo>
	up|update            check every package then update interactively
	                     you could specify a Package to update instead
	rm <name>            remove a package

environment:
	GRM_PROGRAMS_DIR     where packages live      (default: ~/Programs)
	GRM_BIN_DIR          where symlinks are made  (default: ~/bin)
	GITHUB_TOKEN         optional, lifts the 60 requests/hour API limit
EOF
}
formatChecker() {
	if [[ "$1" =~ ^[^/]+/[^/]+$ ]]; then return 0
	else
		echo "Make Sure it Matche the owner/package_name format!"
		return 1
	fi
}
repoExists() {
	status=$(curl -I -s -o /dev/null -w "%{http_code}" "https://github.com/$1/$2" --max-time 3)
	case $status in
		200|301) return 0;;
			*) return 1;;
	esac
}
script_path=$(readlink -f "${BASH_SOURCE[0]}")
script_dir=$(dirname "$script_path")

case "${1:-}" in
	in|install)
		if [[ -z "${2:-}" ]]; then
			printf "specify a url\n" >&2
			exit 1
		fi
		if ! formatChecker $2; then
			exit 1
		fi
		owner="${2%/*}"
		pkg="${2#*/}"
		if ! repoExists "$owner" "$pkg"; then
			printf "Error while trying to locate the repo\n"
			exit 1
		fi
		exec python3 "$script_dir/controller.py" install "$owner" "$pkg"
	;;
	up|update)
		if [[ -z ${2:-} ]]; then
			exec python3 "$script_dir/controller.py" up_all
		fi
		if ! formatChecker $2; then
			exit 1
		fi

		owner="${2%/*}"
		pkg="${2#*/}"
		exec python3 "$script_dir/controller.py" up_one "$owner" "$pkg"
	;;
	rm)
		if [[ -z ${2:-} ]]; then
			printf "Specify a package\n" >&2
			exit 1
		fi
		if ! formatChecker $2; then
			exit 1
		fi
		owner="${2%/*}"
		pkg="${2#*/}"
		exec python3 "$script_dir/controller.py" remove "$owner" "$pkg"
	;;
	list)
		exec python3 "$script_dir/controller.py" list
	;;
	""|help|-h|--help)
		usage
	;;
	*)
		usage
		exit 1
	;;
esac
