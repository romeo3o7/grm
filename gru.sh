#!/usr/bin/env bash
set -euo pipefail

trap cleanup EXIT
trap 'exit 1' INT TERM HUP

## Finds the absolute or relative directory of the script itself
script_path=$(readlink -f "${BASH_SOURCE[0]}")
script_dir=$(dirname "$script_path")
for file in "$script_dir"/*.sh; do
	[[ $file -ef $script_path ]] && continue
	source "$file"
done

programs_dir="$HOME/Programs"

case "${1:-}" in
	install)
		if [[ -z "${2:-}" ]]; then
			printerr "specify a url"
			exit 1
		fi
		install_from_url "$2"
	;;
	update_all) update_all ;;
	update_one)
		[[ -n ${2:-} ]] || { usage; exit 1; }
		update_one "$programs_dir/$2"
	;;
	list) list_packages ;;
	*) usage; exit 0 ;;
esac
