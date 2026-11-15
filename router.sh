#!/usr/bin/env bash

usage() {
	cat <<'EOF'
usage: grm <command> [args]
	list                 list installed packages and their versions
	in|install           install the latest release of <owner>/<repo>
	up|update            check every package (in parallel), then update interactively
	up_one <name>        update one package ("tool" or "tool.owner")
	remove <name>        remove a package and the symlinks that point into it

environment:
	GRM_PROGRAMS_DIR     where packages live      (default: ~/Programs)
	GRM_BIN_DIR          where symlinks are made  (default: ~/bin)
	GITHUB_TOKEN         optional, lifts the 60 requests/hour API limit
EOF
}

script_path=$(readlink -f "${BASH_SOURCE[0]}")
script_dir=$(dirname "$script_path")

case "${1:-}" in
	in|install)
		if [[ -z "${2:-}" ]]; then
			printf "specify a url\n" >&2
			exit 1
		fi
		if ! [[ "$2" =~ ^[^/]+/[^/]+$ ]]; then
			echo "Make Sure it Matche the owner/packageName format!"
			exit 1
		fi
		owner="${2%/*}"
		pkg="${2#*/}"
		exec python3 "$script_dir/controller.py" install "$owner" "$pkg"
	;;
	up|update)
		exec python3 "$script_dir/controller.py" up_all
	;;
	up_one)
		if [[ -z ${2:-} ]]; then
			printf "specify a Package Name; grm list To see Installed Packages\n"
		fi

		if ! [[ "$2" =~ ^[^/]+/[^/]+$ ]]; then
			echo "Make sure it Matche the packageName/owner format!"
			exit 1
		fi
		pkg="${2%/*}"
		owner="${2#*/}"
		exec python3 "$script_dir/controller.py" up_one "$owner" "$pkg"
	;;
#	remove)
#		[[ -n ${2:-} ]] || { usage >&2; exit 2; }
#		remove_package "$2"
#	;;
#	list)
#		list_packages
#	;;
	""|help|-h|--help)
		usage
	;;
	*)
		usage
		exit 1
	;;
esac
