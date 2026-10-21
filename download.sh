install() {
	# called as: install "$asset_name" "$asset_url" "$dir" "$owner" "$project" "$version"
	local asset_name_in=$1
	local asset_url_in=$2
	local program_path=$3
	local owner_in=$4
	local project_in=$5
	local version_in=$6
	local temppath metafilepath

	temp=$(mktemp -d) || return 1
	temppath="$temp"/"$asset_name_in"

	echo "downloading $asset_name_in"
	curl -fL "$asset_url_in" -o "$temppath" || {
		printerr "Error: failed to download $asset_name_in"
		return 1
	}

	newpath=$(mktemp -d "$(dirname "$program_path")/.$(basename "$program_path").XXXXXX") || {
		printerr "Failed to create staging directory"
		return 1
	}

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
			}
			;;
		*) printerr "unsupported archive type: $asset_name_in"; return 1 ;;
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
		printerr "$project: no candidates"
		return 1
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

update() {
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
