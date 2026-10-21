#!/usr/bin/env bash
set -euo pipefail
gru_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$gru_dir/meta.sh"
source "$gru_dir/fetch.sh"
source "$gru_dir/download.sh"
source "$gru_dir/candidate.sh"

printerr() {
	printf '%s\n' "$1" >&2
}

programs_dir="$HOME/Programs"

case "${1:-}" in
	update) update ;;
	*) printerr "usage: gru update"; exit 1 ;;
esac
