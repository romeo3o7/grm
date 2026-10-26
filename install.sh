install() {
	# ca;led as: install "$asset_name" "$asset_url" "$program_path" "$owner" "$project" "$version"
	local asset_name_in=$1
	local asset_url_in=$2
	local program_path_in=$3
	local owner_in=$4
	local project_in=$5
	local version_in=$6
	local temppath metafilepath

	temp=$(mktemp -d) || return 1
	temppath="$temp"/"$asset_name_in"

	printf '\ndownloading %s\n\n' "$asset_name_in"
	curl --connect-timeout 3 --max-time 10 --show-error -fL "$asset_url_in" -o "$temppath" || {
		printerr "Error: failed to download $asset_name_in"
		return 1
	}

	printf 'Successfully Downloaded To Temp\n'

	newpath=$(mktemp -d "$(dirname "$program_path_in")/.$(basename "$program_path_in").XXXXXX") || {
		printerr "Failed to create staging directory"
		return 1
	}

	printf 'created staging directory\n'

	if ! type_reslution "$temppath" "$newpath"; then
		return 1
	fi

	mv "$program_path_in" "$temp" || {
		printerr "failed to delete old version"
		return 1
	}

	mv "$newpath" "$program_path_in" || {
		printerr "failed to move new version"
		mv "$temp/$project_in.$owner_in" "$program_path_in" || {
			printerr "restoration failed"
			return 1
		}
		return 1
	}

	printf '\nsuccessfuly installed %s to %s\n' "$project_in" "$program_path_in"

	metafilepath="$program_path_in"/metaGRUfile
	[[ -e "$metafilepath" ]] || [[ -L "$metafilepath" ]] && {
		printerr 'meta file already exists. skipping creation of metadata. do it manually'
		return 1
	}

	printf 'Owner:%s\nProject:%s\nVersion:%s\nAssetName:%s\n' "$owner_in" "$project_in" "$version_in" "$asset_name_in" > "$metafilepath" || {
		printerr "failed to Write to metadata file"
		return 1
	}
	print_lines
}
