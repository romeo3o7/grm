#!/usr/bin/env bash

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

script_path=$(readlink -f "${BASH_SOURCE[0]}")
script_dir=$(dirname "$script_path")

case "${1:-}" in
	in|install)
		if [[ -z "${2:-}" ]]; then
			printf "specify a url\n" >&2
			exit 1
		fi
		if ! [[ "$2" =~ ^[^/]+/[^/]+$ ]]; then
			echo "Doesn't Matche the a/b format!"
			exit 1
		fi
		owner="${2%/*}"
		pkg="${2#*/}"
		exec python3 "$script_dir/controller.py" install "$owner" "$pkg"
	;;
	up|update)
		exec python3 "$script_dir/controller.py" update
	;;
#	up_one)
#		[[ -n ${2:-} ]] || { usage >&2; exit 2; }
#		resolve_program "$2" target
#		update_one "$target"
#	;;
#	link)
#		[[ -n ${2:-} ]] || { usage >&2; exit 2; }
#		link_package "$2"
#	;;
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
