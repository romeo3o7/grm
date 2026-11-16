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

script_path=$(readlink -f "${BASH_SOURCE[0]}")
script_dir=$(dirname "$script_path")

case "${1:-}" in
	in|install)
		if [[ -z "${2:-}" ]]; then
			printf "specify a url\n" >&2
			exit 1
		fi
		if ! [[ "$2" =~ ^[^/]+/[^/]+$ ]]; then
			echo "Make Sure it Matche the owner/package_name format!"
			exit 1
		fi
		owner="${2%/*}"
		pkg="${2#*/}"
		exists=$(curl -s -o /dev/null -w "%{http_code}" -I "https://github.com/$owner/$pkg")
		if [[ $exists == 200 ]]; then
			exec python3 "$script_dir/controller.py" install "$owner" "$pkg"
		else
			printf "Repo Doesn't Exist\n"
			exit 1
		fi
	;;
	up|update)
		if [[ -z ${2:-} ]]; then
			exec python3 "$script_dir/controller.py" up_all
		fi
		if ! [[ "$2" =~ ^[^/]+/[^/]+$ ]]; then
			echo "Make sure it Matche the owner/package_name format!"
			exit 1
		fi
		owner="${2%/*}"
		pkg="${2#*/}"
		exec python3 "$script_dir/controller.py" up_one "$owner" "$pkg"
	;;
#	remove)
#		[[ -n ${2:-} ]] || { usage >&2; exit 2; }
#		remove_package "$2"
#	;;
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
