api_get() {
	# api_get <path>: GET https://api.github.com/<path>
	# The token goes in through a curl config on an fd, so it never shows up in `ps`.
	local url="https://api.github.com/$1"
	local -a opts=(--connect-timeout 3 --max-time 15 --proto '=https' --show-error -fsS
		-H 'Accept: application/vnd.github+json')

	if [[ -n ${GITHUB_TOKEN:-} ]]; then
		curl "${opts[@]}" -K <(printf 'header = "Authorization: Bearer %s"\n' "$GITHUB_TOKEN") "$url"
	else
		curl "${opts[@]}" "$url"
	fi
}

fetch_latest() {
	# called as: fetch_latest $owner $project
	local owner_in=$1 project_in=$2 json

	if json=$(api_get "repos/$owner_in/$project_in/releases/latest"); then
		printf '%s\n' "$json"
		return 0
	fi

	# /releases/latest hides pre-releases, so repos that only publish those answer 404.
	# Fall back to the newest release of any kind before giving up.
	if json=$(api_get "repos/$owner_in/$project_in/releases?per_page=1") && json=$(jq -e '.[0]' <<< "$json"); then
		printerr "$project_in: no stable release, using the newest pre-release"
		printf '%s\n' "$json"
		return 0
	fi

	printerr "$project_in: github request failed (not found, offline, or rate limited: try setting GITHUB_TOKEN)"
	return 1
}

list_packages() {
	local dir owner project version asset found=0
	local -a links

	for dir in "$programs_dir"/*/; do
		dir=${dir%/}
		read_metadata "$dir" owner project version asset links 2>/dev/null || continue
		printf '%s: %s\n' "${dir##*/}" "$version"
		found=1
	done
	if (( ! found )); then printerr "no packages installed"
	fi
}

write_metadata() {
	# called as write_metadata $dir $owner $project $ver $asset_name links_array_name
	# links are "linkname:relative/path/inside/package" entries
	local dir_in=$1 own=$2 pro=$3 ver=$4 ass_name=$5
	local -n links_in=$6
	local file="$dir_in/metaGRMfile" tmp entry

	if ! tmp=$(mktemp "$dir_in/.meta.XXXXXX"); then
		printerr "failed to create metadata file"
		return 1
	fi

	# write beside the target and rename: a crash never leaves a half-written metaGRMfile.
	# (rename also replaces anything the archive itself shipped under that name)
	if ! {
		printf 'Owner:%s\nProject:%s\nVersion:%s\nAssetName:%s\n' "$own" "$pro" "$ver" "$ass_name"
		for entry in "${links_in[@]}"; do
			printf 'Link:%s\n' "$entry"
		done
	} > "$tmp" || ! mv -f -T -- "$tmp" "$file"; then
		rm -f -- "$tmp"
		printerr "failed to write metadata file"
		return 1
	fi
}

read_metadata() {
	# called as: read_metadata $dir owner project version asset_name links
	# links is filled with "linkname:relative/path" entries and may stay empty (old metadata has none)
	local dir=$1
	local -n owner_out=$2
	local -n project_out=$3
	local -n version_out=$4
	local -n asset_name_out=$5
	local -n links_out=$6
	local key value

	owner_out="" project_out="" version_out="" asset_name_out="" links_out=()

	[[ -r $dir/metaGRMfile ]] || return 1

	# one pass in pure bash instead of cat + 4x (grep | sed); the value keeps any ':' it contains
	while IFS=: read -r key value || [[ -n $key ]]; do
		case $key in
			Owner)     owner_out=$value ;;
			Project)   project_out=$value ;;
			Version)   version_out=$value ;;
			AssetName) asset_name_out=$value ;;
			Link)      links_out+=("$value") ;;
		esac
	done < "$dir/metaGRMfile"

	if [[ -z $owner_out || -z $project_out || -z $version_out || -z $asset_name_out ]]; then
		printerr "empty metadata field"
		return 1
	fi
}
