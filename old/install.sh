verify_digest() {
	# verify_digest $file $digest   (digest is "sha256:<hex>", or "-" when github did not provide one)
	local file_in=$1 digest_in=$2 expected actual

	case "$digest_in" in
		sha256:*) expected=${digest_in#sha256:} ;;
		*)
			printerr "warning: no sha256 digest published for this asset, integrity not verified"
			return 0
			;;
	esac

	if ! actual=$(sha256sum -- "$file_in"); then
		printerr "could not hash $file_in"
		return 1
	fi
	actual=${actual%% *}

	if [[ ${actual,,} != "${expected,,}" ]]; then
		printerr "CHECKSUM MISMATCH: expected $expected, got $actual. refusing to install"
		return 1
	fi
	printf 'sha256 verified\n'
}

install_package() {
	# called as: install_package asset_name asset_url asset_digest program_path owner project version links_array_name
	# returns 0 ok, 1 failure, 2 cancelled. Until the swap nothing in $program_path is touched,
	# and the metadata is written BEFORE the swap, so nothing can fail once the old version is moved away.
	local asset_name_in=$1
	local asset_url_in=$2
	local asset_digest_in=$3
	local program_path_in=$4
	local owner_in=$5
	local project_in=$6
	local version_in=$7
	local -n links_io=$8
	local parent base downloaded entry lname lrel rc picked default_name status=0
	local -a kept_links=()

	if [[ $asset_name_in == */* ]]; then
		printerr "refusing asset name containing '/'"
		return 1
	fi

	parent=$(dirname -- "$program_path_in")
	base=$(basename -- "$program_path_in")
	default_name=$project_in

	if ! mkdir -p -- "$parent"; then
		printerr "cannot create $parent"
		return 1
	fi

	temp=$(mktemp -d) || return 1
	downloaded="$temp/$asset_name_in"

	printf '\ndownloading %s\n\n' "$asset_name_in"
	if ! curl --connect-timeout 3 --proto '=https' --proto-redir '=https' --retry 2 --show-error -fL "$asset_url_in" -o "$downloaded"; then
		printerr "Error: failed to download $asset_name_in"
		return 1
	fi
	printf '\nSuccessfully Downloaded To Temp\n'

	verify_digest "$downloaded" "$asset_digest_in" || return 1

	# staging dir lives next to the target: same filesystem, so the final steps are renames
	if ! newpath=$(mktemp -d "$parent/.$base.XXXXXX"); then
		printerr "Failed to create staging directory"
		return 1
	fi

	rc=0
	extract_asset "$downloaded" "$newpath" || rc=$?
	if (( rc != 0 )); then return "$rc"
	fi

	# keep the links whose binary is still there in the new version, ask again only for the rest
	for entry in "${links_io[@]}"; do
		lname=${entry%%:*}
		lrel=${entry#*:}
		if [[ -f $newpath/$lrel && -x $newpath/$lrel ]]; then
			kept_links+=("$entry")
		else
			printerr "link '$lname': $lrel is not in this version"
			default_name=$lname
		fi
	done

	if (( ${#kept_links[@]} == 0 )); then
		rc=0
		choose_link "$newpath" "$program_path_in" "$default_name" picked || rc=$?
		case $rc in
			0) kept_links+=("$picked") ;;
			3) printerr "no executable found, installing without a link" ;;
			*) return "$rc" ;;
		esac
	fi

	if ! write_metadata "$newpath" "$owner_in" "$project_in" "$version_in" "$asset_name_in" kept_links; then
		return 1
	fi

	# ---- the swap: two renames on one filesystem ----
	if [[ -e $program_path_in || -L $program_path_in ]]; then
		oldpath="$parent/.$base.old.$$.$RANDOM"
		swap_target=$program_path_in
		if ! mv -T -- "$program_path_in" "$oldpath"; then
			printerr "failed to move the old version aside"
			oldpath="" swap_target=""
			return 1
		fi
	fi

	if ! mv -T -- "$newpath" "$program_path_in"; then
		printerr "failed to move new version into place"
		if [[ -n $oldpath ]]; then
			# -T: rename onto the path, never "into" a directory that happens to be there
			if mv -T -- "$oldpath" "$program_path_in"; then
				oldpath=""
			else
				printerr "restoration failed, the old version is in $oldpath"
			fi
		fi
		swap_target=""
		return 1
	fi
	newpath=""

	# only now is the backup expendable
	if [[ -n $oldpath ]]; then rm -rf -- "$oldpath"
	fi
	oldpath="" swap_target=""

	printf '\nsuccessfully installed %s to %s\n' "$project_in" "$program_path_in"

	for entry in "${kept_links[@]}"; do
		link_one "$program_path_in" "$entry" || status=1
	done

	case ":$PATH:" in
		*":$bin_dir:"*) ;;
		*) printerr "note: $bin_dir is not in your PATH" ;;
	esac

	return "$status"
}
