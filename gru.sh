#!/usr/bin/env bash
set -euo pipefail

printerr() {
	printf '\n%s\n' "$1" >&2
}

usage() {
printf 'update_all: update all Programs in %s\nupdate_one: update one package, directory name is required\n' "$programs_dir"
}

fetch_latest() {
	# called as: fetch_latest $owner $project
	local owner_in=$1
	local project_in=$2
	curl -fsS "https://api.github.com/repos/$owner_in/$project_in/releases/latest"
}

read_metadata() {
	# called as: read_metadata $dir owner project perversion
	local dir=$1
	local -n owner_out=$2
	local -n project_out=$3
	local -n version_out=$4
	local metadatafile

	metadatafile=$(cat "$dir/metaGRUfile" 2>/dev/null) || {
		return 1
	}

	owner_out=$(   grep '^Owner:'   <<< "$metadatafile" | sed 's|Owner:||'   | tr -d ' \r\n') || return 1
	project_out=$( grep '^Project:' <<< "$metadatafile" | sed 's|Project:||' | tr -d ' \r\n') || return 1
	version_out=$( grep '^Version:' <<< "$metadatafile" | sed 's|Version:||' | tr -d ' \r\n') || return 1
}

filter_find_candidates() {
	# Called as: filter_find_candidates "$github_json"
	local github_json_in=$1
	local sep_l='(^|[^[:alnum:]])'
	local sep_r='([^[:alnum:]]|$)'
	local arch_filter arch os_filter ext_filter

	arch=$(uname -m) || {
		echo "failed to retrive machine arch"
		return 1
	}

	case "$arch" in
		x86_64)  arch_filter="${sep_l}(x86_64|amd64|x64)${sep_r}" ;;
		aarch64) arch_filter="${sep_l}(aarch64|arm64)${sep_r}" ;;
		*)
			printerr "unsupported arch: $arch"
			return 1
			;;
	esac

	os_filter="${sep_l}(darwin|macos|osx|apple|mac|windows|win(32|64)?|msvc|freebsd|openbsd|netbsd|dragonfly|illumos|solaris|android|ios)${sep_r}"
	ext_filter='\.tar\.(gz|xz|zst|bz2)$|\.tgz$|\.zip$|\amd64$|\linux$'

	jq -r \
		--arg arch "$arch_filter" \
		--arg ext "$ext_filter" \
		--arg os "$os_filter" '
		.assets[]
		| select(.name | test($ext; "i"))
		| select(.name | test($arch; "i"))
		| select((.name | test($os; "i")) | not)
		| [.name, .browser_download_url] | @tsv
	' <<< "$github_json_in"

}

return_all_candidates() {
	local github_json_in=$1
	jq -r \
		 '.assets[]
		| [.name, .browser_download_url] | @tsv
	' <<< "$github_json_in"
}

select_candidate_url() {
	# Called as: select_candidate_url "$candidates" asset_name asset_url
	local candidates_in=$1
	local -n asset_name_out=$2
	local -n asset_url_out=$3
	local -a lines
	local i reply choice selected

	mapfile -t lines <<< "$candidates_in"

	while true; do
		if (( ${#lines[@]} == 1 )); then
			choice=0
		else
			for i in "${!lines[@]}"; do
				printf '%2d) %s\n' "$((i + 1))" "${lines[i]%%$'\t'*}" >&2
			done

			while true; do
				read -r -p "Pick an asset [1-${#lines[@]}], q to quit: " reply || return 1
				case "${reply,,}" in
					q) return 2 ;;
				esac

				if [[ $reply =~ ^[0-9]+$ ]] &&
				   (( 10#$reply >= 1 && 10#$reply <= ${#lines[@]} )); then
					choice=$((10#$reply - 1))
					break
				fi
				printerr "Invalid choice"
			done
		fi

		selected=${lines[choice]}
		asset_name_out=${selected%%$'\t'*}

		while true; do
			read -r -p "Selected asset: $asset_name_out. Is that correct? [y/n/q] " reply || return 1

			case "${reply,,}" in
				y)
					asset_url_out=${selected#*$'\t'}
					return 0
					;;
				n)
					if (( ${#lines[@]} == 1 )); then
						printerr "Selection cancelled"
						return 2
					fi
					break
					;;
				q) return 2 ;;
				*) printerr "Please enter y, n, or q." ;;
			esac
		done
	done
}

parse_github_url() {
	# called as: parse_github_url "$url" owner project
	local url_in=$1
	local -n owner_out=$2
	local -n project_out=$3
	local rest o p extra

	case "$url_in" in
		https://github.com/*) rest=${url_in#https://github.com/} ;;
		*) printerr "not a https://github.com/ url"; return 1 ;;
	esac

	rest=${rest%%[?#]*}    # drop ?query and #fragment
	rest=${rest%/}         # drop one trailing slash
	IFS=/ read -r o p extra <<< "$rest"
	p=${p%.git}            # https://github.com/owner/repo.git

	[[ -n $o && -n $p ]] || { printerr "url has no owner/repo"; return 1; }
	case "$o" in *[!A-Za-z0-9._-]*) printerr "bad owner name"; return 1 ;; esac
	case "$p" in *[!A-Za-z0-9._-]*) printerr "bad repo name"; return 1 ;; esac
	[[ $o == . || $o == .. || $p == . || $p == .. ]] && { printerr "bad name"; return 1; }

	owner_out=$o
	project_out=$p
}

install_from_url() {
	local url=$1
	local owner project github_json latversion candidates dir asset_name asset_url status rc=0
	local temp="" temppath=""
	parse_github_url "$url" owner project || return 1
	github_json=$(fetch_latest "$owner" "$project") || {
		printerr "$project: no response from github"
		return 1
	}
	latversion=$(jq -r '.tag_name // empty' <<< "$github_json")
	[[ -z "$latversion" ]] && { printerr "$project: can't find version ~empty json"; return 1; }
	candidates=$(filter_find_candidates "$github_json") || {
		printerr "$project: filtering assets failed"
		return 1
	}
	[[ -n $candidates ]] || {
		printerr "$project: no candidates, attempting to list all candidates"
		candidates=$(return_all_candidates "$github_json")
		[[ -n "$candidates" ]] || {
			printerr "nothing"
			return 1
		}
	}

	select_candidate_url "$candidates" asset_name asset_url || {
		status=$?
		[[ $status -eq 2 ]] && return 0
		return 1
	}
	local program_path="$programs_dir/$project"
	mkdir -p "$program_path"
	install "$asset_name" "$asset_url" "$program_path" "$owner" "$project" "$latversion" || rc=1
	if [[ -n $temp ]]; then rm -rf "$temp"; fi
	if [[ -n $newpath ]]; then rm -rf "$newpath"; fi

	return "$rc"
}

install() {
	# called as: install "$asset_name" "$asset_url" "$program_path" "$owner" "$project" "$version"
	local asset_name_in=$1
	local asset_url_in=$2
	local program_path=$3
	local owner_in=$4
	local project_in=$5
	local version_in=$6
	local temppath metafilepath

	temp=$(mktemp -d) || return 1
	temppath="$temp"/"$asset_name_in"

	printf '\ndownloading %s\n' "$asset_name_in"
	curl -fL "$asset_url_in" -o "$temppath" || {
		printerr "Error: failed to download $asset_name_in"
		return 1
	}

	newpath=$(mktemp -d "$(dirname "$program_path")/.$(basename "$program_path").XXXXXX") || {
		printerr "Failed to create staging directory"
		return 1
	}
	printf '\ncreated staging directory %s\n' "$newpath"

	case "${asset_name_in,,}" in
		*.tar.gz|*.tgz|*.tar.xz|*.tar.zst|*.tar.bz2)
			tar -xf "$temppath" -C "$newpath" || {
				printerr "Extracting $temppath failed"
				return 1
			}
			;;
		*.zip)
			unzip -o "$temppath" -d "$newpath" > /dev/null || {
				printerr "unziping $temppath failed"
				return 1
			} ;;
		*) printerr "unfamiliar type: $asset_name_in";
			while true; do
				read -r -n 1 -p "$project_in will be removed, unlesss you want to install it as it ? (y/n): " reply || return 1
				case "${reply,,}" in
					"y")
						mv "$temppath" "$newpath" || {
							printerr "failed to move $temppath to $newpath"
							return 1
						}
					break
					;;
					"n") return 1;;
					*) printerr "try again"
				esac
			done
			;;
	esac

	metafilepath="$newpath"/metaGRUfile
	printf 'Owner:%s\nProject:%s\nVersion:%s\n' "$owner_in" "$project_in" "$version_in" > "$metafilepath" || {
		printerr "failed to Write to metadata file"
		return 1
	}

	del "$program_path" || {
		printerr "failed to delete old version"
		return 1
	}

	mv "$newpath" "$program_path" || {
		printerr "failed to move new version"
		del --restore "$program_path" || {
			printerr "restoration failed, the old version is in the trash"
			return 1
		}
		return 1
	}
	printf '\nsuccessfuly installed %s to %s\n' "$project_in" "$program_path"
}

update_one() {
	# called as: update_one "$dir"
	# returns 0 for updated / up to date / user declined, 1 for a failure
	local dir=$1
	local owner project perversion latversion github_json candidates
	local asset_name asset_url reply status rc=0
	local temp="" newpath=""   # filled in by install, cleaned up below

	read_metadata "$dir" owner project perversion || {
		printerr "$dir: could not read metadata"
		return 1
	}
	echo "$project: querying for latest release, current: $perversion"

	github_json=$(fetch_latest "$owner" "$project") || {
		printerr "$project: no response from github"
		return 1
	}

	latversion=$(jq -r '.tag_name // empty' <<< "$github_json")
	[[ -n $latversion ]] || {
		printerr "$project: could not get latest version"
		return 1
	}
	if [[ $latversion == "$perversion" ]]; then
		printerr "$project is up to date. version: $latversion"
		return 0
	fi
	printf 'New version found: %s\n' "$latversion"

	while true; do
		read -r -p "Should we update $project? [y/n] " reply || return 1
		[[ $reply == n ]] || [[ $reply == q ]] && return 0
		[[ $reply == y ]] && break
	done

	candidates=$(filter_find_candidates "$github_json") || {
		printerr "$project: filtering assets failed"
		return 1
	}
	[[ -n $candidates ]] || {
		printerr "$project: no candidates post filtering, attempting to list all candidates"
		candidates=$(return_all_candidates "$github_json")
		[[ -n "$candidates" ]] || {
			printerr "nothing"
			return 1
		}
	}

	select_candidate_url "$candidates" asset_name asset_url || {
		status=$?
		[[ $status -eq 2 ]] && return 0
		return 1
	}

	install "$asset_name" "$asset_url" "$dir" "$owner" "$project" "$latversion" || rc=1

	if [[ -n $temp ]]; then rm -rf "$temp"; fi
	if [[ -n $newpath ]]; then rm -rf "$newpath"; fi
	return "$rc"
}

update_all() {
	failures=0
	for dir in "$programs_dir"/*; do
		[[ -f $dir/metaGRUfile ]] || continue
		update_one "$dir" || failures=$((failures + 1))
	done

	if (( failures > 0 )); then
		printerr "$failures program(s) failed"
		return 1
	fi
 }

programs_dir="$HOME/Programs"

case "${1:-}" in
	install) install_from_url "${2:-}" ;;
	update_all) update_all ;;
	update_one) update_one "$programs_dir"/"${2:-}" ;;
	*) usage; exit 1 ;;
esac
