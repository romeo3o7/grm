#!/usr/bin/env bash
set -euo pipefail

printerr() {
	printf '%s\n' "$1" >&2
}
programs_dir="$HOME/Programs"
for dir in "$programs_dir"/*; do
	[[ -f "$dir/metaGRUfile" ]] || continue
	metadatafile=$(cat "$dir/metaGRUfile") || { printerr "meta file not found"; exit 1; }
	owner=$(echo "$metadatafile" | grep "Owner:"   | sed 's|Owner:||'   | tr -d ' \r\n') || exit 1
	project=$(echo "$metadatafile" | grep "Project:" | sed 's|Project:||' | tr -d ' \r\n') || exit 1
	perversion=$(echo "$metadatafile" | grep "Version:" | sed 's|Version:||' | tr -d ' \r\n') || exit 1
	echo "$project: querying For $project latest release"

	github_json=$(curl -fsS "https://api.github.com/repos/$owner/$project/releases/latest") || {
		printerr "Error: No response from github";
		exit 1;
	}

	latversion=$(jq -r '.tag_name // empty' <<< "$github_json")
	#
	[[ -z $latversion ]] && { printerr "Error: Could not get latest version for $project"; exit 1; }
	[[ "$latversion" == "$perversion" ]] && { printerr "$project is up to date. version:$latversion"; continue; }
	printf 'Current Version:%s, New Version found:%s\n' "$perversion" "$latversion"

	while true; do
		read -r -p "Should we Update? [y/n] " reply || exit 1
		[[ "$reply" == n ]] || [[ "$reply" == q ]] && continue 2
		[[ "$reply" == y ]] && break
	done

	 # -------- instalation bits
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
			read -r -p "Pick An Asset To Download [1-${#lines[@]}], q to quit: " reply || exit 1
			[[ $reply == q ]] && continue 2
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

	while true; do
		read -r -p "Selected Asset Name:$asset_name is that ok? [y/n] " reply || exit 1
		[[ $reply == n ]] || [[ $reply == q ]] && continue
		[[ $reply == y ]] && break
		printerr "try again"
	done

	temp=$(mktemp -d)
	temppath="$temp"/"$asset_name"

	echo "installing to $temp"
	curl -fL "$asset_url" -o "$temppath" || {
		printerr "Error: failed to download $asset_name";
		exit 1;
	}

	newpath=$(mktemp -d "$programs_dir/${project}.XXXXXX") || {
	    printerr "Failed to create staging directory"
	    exit 1
	}

	case "${asset_name,,}" in
		*.tar.gz|*.tgz|*.tar.xz|*.tar.zst|*.tar.bz2)
		tar -xf "$temppath" -C "$newpath" || {
	            printerr "Extracting $temppath failed"
	            exit 1
		}
		;;
		*.zip)
			unzip -o "$temppath" -d "$newpath" > /dev/null || {
				printerr "unziping $temppath failed"
				exit 1
			}
		;;
		*) printerr "unsupported archive type: $asset_name"; exit 1 ;;
	esac

	metafilepath="$newpath"/metaGRUfile
	printf 'Owner:%s\nProject:%s\nVersion:%s\n' "$owner" "$project" "$latversion" > "$metafilepath" || {
		printerr "failed to Write to metadata file"
		exit 1
	}

	program_path="$programs_dir/$project"
	del "$program_path" || {
		printerr "failed to delete old version"
		exit 1
	}

	mv "$newpath" "$program_path" || {
		printerr "failed to move new version"
		del --restore "$program_path" || {
			printerr "restoration failed"
			exit 1
		}
		exit 1
	}
done
