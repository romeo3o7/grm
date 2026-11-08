#!/usr/bin/env bash
set -euo pipefail

# namerefs (declare -n) and mapfile -d need bash 4.4
if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4) )); then
	printf 'grm needs bash >= 4.4\n' >&2
	exit 1
fi

# state the EXIT trap needs to see
temp="" newpath="" oldpath="" swap_target="" api_tmp=""

## Finds the absolute or relative directory of the script itself
script_path=$(readlink -f "${BASH_SOURCE[0]}")
script_dir=$(dirname "$script_path")

# an explicit list: a stray test.sh or backup.sh next to us is no longer executed by accident
for module in gp metadata candidate type probin install url update manage; do
	# shellcheck source=/dev/null
	source "$script_dir/$module.sh"
done

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

for cmd in curl jq file tar sha256sum mktemp realpath; do
	if ! command -v "$cmd" >/dev/null; then
		printerr "missing dependency: $cmd"
		exit 1
	fi
done

programs_dir="${GRM_PROGRAMS_DIR:-$HOME/Programs}"
bin_dir="${GRM_BIN_DIR:-$HOME/bin}"

case "${1:-}" in
	install)
		if [[ -z "${2:-}" ]]; then
			printerr "specify a url"
			exit 2
		fi
		mkdir -p -- "$programs_dir"
		install_from_url "$2"
	;;
	up_all)
		update_all
	;;
	up_one)
		[[ -n ${2:-} ]] || { usage >&2; exit 2; }
		resolve_program "$2" target
		update_one "$target"
	;;
	outdated)
		list_outdated
	;;
	link)
		[[ -n ${2:-} ]] || { usage >&2; exit 2; }
		link_package "$2"
	;;
	remove)
		[[ -n ${2:-} ]] || { usage >&2; exit 2; }
		remove_package "$2"
	;;
	list)
		list_packages
	;;
	""|help|-h|--help)
		usage
	;;
	*)
		usage >&2
		exit 2
	;;
esac
