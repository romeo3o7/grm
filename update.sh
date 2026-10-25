update_all() {
	print_lines
	local failures=0
	for dir in "$programs_dir"/*; do
		[[ -f $dir/metaGRUfile ]] || continue
		update_one "$dir" || failures=$((failures + 1))
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

	metadatafile=$(cat "$dir/metaGRUfile" 2>/dev/null) || return 1
	owner_out=$(      grep '^Owner:'     <<< "$metadatafile" | sed 's|Owner:||'     | tr -d '\n') || return 1
	project_out=$(    grep '^Project:'   <<< "$metadatafile" | sed 's|Project:||'   | tr -d '\n') || return 1
	version_out=$(    grep '^Version:'   <<< "$metadatafile" | sed 's|Version:||'   | tr -d '\n') || return 1
	asset_name_out=$( grep '^AssetName:' <<< "$metadatafile" | sed 's|AssetName:||' | tr -d '\n') || return 1

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
	local asset_name asset_url reply status rc=0
	local temp="" newpath=""   # filled in by install, cleaned up below

	read_metadata "$program_path" owner project perversion asset_name || {
		printerr "read_metadata: existing metadata lookup"
		return 1
	}

	printf '%s: querying for latest release, current: %s\n' "$project" "$perversion"

	github_json=$(fetch_latest "$owner" "$project") || {
		printerr "$project: no response from github"
		return 1
	}

	latversion=$(jq -r '.tag_name // empty' <<< "$github_json")
	[[ -n $latversion ]] || {
		printerr "could not get latest version, Possibly Empty JSON"
		return 1
	}

	if [[ $latversion == "$perversion" ]]; then
		printf 'up to date\n'
		print_lines
		return 0
	fi

	printf 'New version found: %s\n' "$latversion"

	while true; do
		read -r -p "Should we update $project? [y/n] " reply || return 1
		case ${reply,,} in
			n|q) return 0 ;;
			y) break ;;
			*) printf 'input not understood\n' ;;
		esac
	done

	candidates=$(find_candidates "$github_json" "$asset_name") || return 1

	select_candidate_url "$candidates" asset_name asset_url || {
		status=$?
		[[ $status -eq 2 ]] && return 0
		return 1
	}

	install "$asset_name" "$asset_url" "$program_path" "$owner" "$project" "$latversion" || rc=1

	if [[ -n $temp ]]; then rm -rf "$temp"; fi
	if [[ -n $newpath ]]; then rm -rf "$newpath"; fi
	return "$rc"
}
