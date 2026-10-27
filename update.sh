update_all() {
	print_lines
	local failures=0
	for dir in "$programs_dir"/*; do
		if ! [[ -f $dir/metaGRUfile ]]; then
			continue
		fi
		if ! update_one "$dir"; then
			failures=$((failures + 1))
		fi
	print_lines
	done

	if (( failures > 0 )); then
		printerr "$failures program(s) failed"
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

	if ! metadatafile=$(cat "$dir/metaGRUfile" 2>/dev/null); then
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

update_one() {
	# called as: update_one "$dir"
	local program_path=$1
	local owner project perversion latversion github_json candidates
	local asset_name asset_url reply status=0

	if ! read_metadata "$program_path" owner project perversion asset_name; then
		printerr "read_metadata: existing metadata lookup"
		return 1
	fi

	printf '%s: querying for latest release, current: %s\n' "$project" "$perversion"

	if ! github_json=$(fetch_latest "$owner" "$project"); then
		printerr "$project: no response from github"
		return 1
	fi

	latversion=$(jq -r '.tag_name // empty' <<< "$github_json")
	if [[ -z $latversion ]]; then
		printerr "could not get latest version, Possibly Empty JSON"
		return 1
	fi

	if [[ $latversion == "$perversion" ]]; then
		printf 'up to date\n'
		return 0
	fi

	printf 'New version found: %s\n' "$latversion"

	while true; do
		if ! read -r -p "Should we update $project? [y/n] " reply ; then
			return 1
		fi
		case ${reply,,} in
			y) break ;;
			n) return 0 ;;
			*) printf 'input not understood\n' ;;
		esac
	done

	if ! candidates=$(find_candidates "$github_json" "$asset_name"); then
		return 1
	fi

	if ! select_candidate_url "$candidates" asset_name asset_url; then
		[[ "$?" -eq 2 ]] && return 0
		return 1
	fi

	if ! install "$asset_name" "$asset_url" "$program_path" "$owner" "$project" "$latversion"; then
		status=1
	fi

	cleanup

	return "$status"
}
