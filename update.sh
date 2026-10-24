update_all() {
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

read_metadata() {
	# called as: read_metadata $dir owner project perversion asset_name
	local dir=$1
	local -n owner_out=$2
	local -n project_out=$3
	local -n version_out=$4
	local -n asset_name_out=$5
	local metadatafile

	metadatafile=$(cat "$dir/metaGRUfile" 2>/dev/null) || {
		return 1
	}

	owner_out=$(   grep '^Owner:'     <<< "$metadatafile" | sed 's|Owner:||'     | tr -d ' \r\n') || return 1
	project_out=$( grep '^Project:'   <<< "$metadatafile" | sed 's|Project:||'   | tr -d ' \r\n') || return 1
	version_out=$( grep '^Version:'   <<< "$metadatafile" | sed 's|Version:||'   | tr -d ' \r\n') || return 1
	asset_name_out=$( grep '^AssetName:' <<< "$metadatafile" | sed 's|AssetName:||' | tr -d ' \r\n') || return 1
}

update_one() {
	# called as: update_one "$dir"
	local dir=$1
	local owner project perversion latversion github_json candidates
	local asset_name asset_url reply status rc=0
	local temp="" newpath=""   # filled in by install, cleaned up below

	read_metadata "$dir" owner project perversion asset_name || {
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
		for i in {0..40}; do
			printf '='
		done
		printf '\n'
		return 0
	fi
	printf 'New version found: %s\n' "$latversion"

	while true; do
		read -r -p "Should we update $project? [y/n] " reply || return 1
		[[ $reply == n ]] || [[ $reply == q ]] && return 0
		[[ $reply == y ]] && break
	done

	candidates=$(find_candidates "$github_json" "$asset_name")

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
