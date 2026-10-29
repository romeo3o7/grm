fetch_latest() {
	# called as: fetch_latest $owner $project
	local owner_in=$1
	local project_in=$2
	curl --connect-timeout 3 --max-time 15 --show-error -fsS "https://api.github.com/repos/$owner_in/$project_in/releases/latest"
}

list_packages() {
	local metadatafile version dir
	for dir in "$programs_dir/"/*; do
		metadatafile=$(cat "$dir/metaGRMfile" 2>/dev/null) || continue
		version=$(grep '^Version:' <<< "$metadatafile" | sed 's|Version:||') || continue
		printf '%s: %s\n' "${dir##*/}" "$version"
	done
}

write_metadata() {
	# called as write_metadata $path $owner $project $ver $ass
	local path_in=$1 own=$2 pro=$3 ver=$4 ass_name=$5
	metafilepath="$path_in"/metaGRMfile
	if [[ -e "$metafilepath" ]] || [[ -L "$metafilepath" ]]; then
		printerr 'meta file already exists. skipping creation of metadata. do it manually'
		return 1
	fi

	if ! printf 'Owner:%s\nProject:%s\nVersion:%s\nAssetName:%s\n' "$own" "$pro" "$ver" "$ass_name" > "$metafilepath"; then
		printerr "failed to Write to metadata file"
		return 1
	fi
}

read_metadata() {
	# called as: read_metadata $dir owner project perversion asset_name
	local dir=$1
	local -n owner_out=$2
	local -n project_out=$3
	local -n version_out=$4
	local -n asset_name_out=$5
	local metadatafile var

	if ! metadatafile=$(cat "$dir/metaGRMfile" 2>/dev/null); then
		return 1
	fi
	if ! owner_out=$(grep '^Owner:' <<< "$metadatafile" | sed 's|Owner:||'); then
		return 1
	fi
	if ! project_out=$(grep '^Project:' <<< "$metadatafile" | sed 's|Project:||'); then
		return 1
	fi
	if ! version_out=$(grep '^Version:' <<< "$metadatafile" | sed 's|Version:||'); then
		return 1
	fi
	if ! asset_name_out=$(grep '^AssetName:' <<< "$metadatafile" | sed 's|AssetName:||' ); then
		return 1
	fi

	for var in "$owner_out" "$project_out" "$version_out" "$asset_name_out" ;do
		if [[ -z "$var" ]]; then
			printerr "empty metadata field"
			return 1
		fi
	done
}

