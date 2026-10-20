#!/usr/bin/env bash
set -euo pipefail

printerr() {
	printf '%s\n' "$1" >&2
}

metadatafile=$(cat "/home/romeo/Programs/brave/update/meta") || { printerr "meta file not found"; exit 1; }
owner=$(echo "$metadatafile" | grep "Owner:"   | sed 's|Owner:||'   | tr -d ' \r\n') || exit 1
project=$(echo "$metadatafile" | grep "Project:" | sed 's|Project:||' | tr -d ' \r\n') || exit 1
perversion=$(echo "$metadatafile" | grep "Version:" | sed 's|Version:||' | tr -d ' \r\n') || exit 1

github_json=$(curl -fsS "https://api.github.com/repos/$owner/$project/releases/latest") || {
	printerr "Error: No response from github";
	exit 1;
}

latversion=$(jq -r '.tag_name // empty' <<< "$github_json")
[[ -z $latversion ]] && { printerr "Error: Could not get latest version for $project"; exit 1; }
[[ "$latversion" == "$perversion" ]] && { printerr "$project is up to date. version:$latversion"; exit 2; }

printf 'New Version found:%s\n' "$latversion"
sep_l='(^|[^[:alnum:]])'
sep_r='([^[:alnum:]]|$)'
arch_filter=
arch=$(uname -m) || exit 1
case "$arch" in
	x86_64)  arch_filter="${sep_l}(x86_64|amd64|x64)${sep_r}" ;;
	aarch64) arch_filter="${sep_l}(aarch64|arm64)${sep_r}" ;;
	*)       printerr "unsupported arch: $arch"; exit 1 ;;
esac
os_filter="${sep_l}(darwin|macos|osx|apple|mac|windows|win(32|64)?|msvc|freebsd|openbsd|netbsd|dragonfly|illumos|solaris|android|ios)${sep_r}"
ext_filter='\.tar\.(gz|xz|zst|bz2)$|\.tgz$|\.zip$'
candidates=$(jq -r --arg arch "$arch_filter" --arg ext "$ext_filter" --arg os "$os_filter" '
  .assets[]
  | select(.name | test($ext; "i"))
  | select(.name | test($arch; "i"))
  | select((.name | test($os; "i")) | not)
  | [.name, .browser_download_url] | @tsv
  ' <<< "$github_json")
  [[ -z "$candidates" ]] && { printerr "no candidates"; exit 1;}

mapfile -t lines <<< "$candidates"

if (( ${#lines[@]} == 1 )); then
	choice=0
else
	for i in "${!lines[@]}"; do
		printf '%2d) %s\n' "$((i + 1))" "${lines[i]%%$'\t'*}" >&2
	done
	while true; do
		read -r -p "Pick [1-${#lines[@]}], q to quit: " reply || exit 1
		[[ $reply == q ]] && exit 0
		if [[ $reply =~ ^[0-9]+$ ]] && (( 10#$reply >= 1 && 10#$reply <= ${#lines[@]} )); then
			choice=$((10#$reply - 1))
			break
		fi
		printerr "invalid choice"
	done
fi

selected=${lines[choice]}
asset_name=${selected%%$'\t'*}
asset_url=${selected#*$'\t'}
