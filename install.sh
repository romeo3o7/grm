install() {
	# called as: install "$asset_name" "$asset_url" "$program_path" "$owner" "$project" "$version"
	# if its called, the caller should remove temp And newpath
	local asset_name_in=$1
	local asset_url_in=$2
	local program_path_in=$3
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

	printf 'Successfully Downloaded To Temp\n'

	newpath=$(mktemp -d "$(dirname "$program_path_in")/.$(basename "$program_path_in").XXXXXX") || {
		printerr "Failed to create staging directory"
		return 1
	}

	printf 'created staging directory\n'

	case "${asset_name_in,,}" in
		*.tar.gz|*.tgz|*.tar.xz|*.tar.zst|*.tar.bz2|*.tar)
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
		printerr 'meta file already exists\nskipping creation of metadata\ndo it manually'
		return 1
	}

	printf 'Owner:%s\nProject:%s\nVersion:%s\nAssetName:%s\n' "$owner_in" "$project_in" "$version_in" > "$metafilepath" "$asset_name_in" || {
		printerr "failed to Write to metadata file"
		return 1
	}
	print_lines
}
