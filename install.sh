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
	if ! curl --connect-timeout 3 --show-error -fL "$asset_url_in" -o "$temppath"; then
		printerr "Error: failed to download $asset_name_in"
		return 1
	fi

	printf '\nSuccessfully Downloaded To Temp\n'

	if ! newpath=$(mktemp -d "$(dirname "$program_path_in")/.$(basename "$program_path_in").XXXXXX"); then
		printerr "Failed to create staging directory"
		return 1
	fi

	printf '\ncreated staging directory\n'

	if ! type_reslution "$temppath" "$newpath"; then
		return 1
	fi

	if ! mv "$program_path_in" "$temp"; then
		printerr "failed to delete old version"
		return 1
	fi

	if ! mv "$newpath" "$program_path_in"; then
		printerr "failed to move new version"
		if ! mv "$temp/$project_in.$owner_in" "$program_path_in"; then
			printerr "restoration failed"
			return 1
		fi
		return 1
	fi

	printf '\nsuccessfuly installed %s to %s\n' "$project_in" "$program_path_in"

	if write_metadata "$program_path_in" "$owner_in" "$project_in" "$version_in" "$asset_name_in"; then :
	else
		printerr "metadata failed.. attempting to restore the old directory"
		mv "$temp/$project_in.$owner_in" "$program_path_in"
		return 1
	fi

	if prob_bin "$program_path_in"; then :
	else return $?
	fi
}
