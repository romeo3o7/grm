install() {
	# called as: install "$asset_name" "$asset_url" "$program_path" "$owner" "$project" "$version"
	# if its called, the caller should remove temp And temppath
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
	printf 'Owner:%s\nProject:%s\nVersion:%s\nAssetName:%s\n' "$owner_in" "$project_in" "$version_in" > "$metafilepath" "$asset_name_in" || {
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
	for i in {0..40}; do
		printf '='
	done
	printf '\n'
}
