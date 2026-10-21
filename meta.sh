read_metadata() {
	# called as: read_metadata $dir owner project perversion
	local dir=$1
	local -n owner_out=$2
	local -n project_out=$3
	local -n version_out=$4
	local metadatafile

	metadatafile=$(cat "$dir/metaGRUfile" 2>/dev/null) || {
		return 1
	}

	owner_out=$(   grep '^Owner:'   <<< "$metadatafile" | sed 's|Owner:||'   | tr -d ' \r\n') || return 1
	project_out=$( grep '^Project:' <<< "$metadatafile" | sed 's|Project:||' | tr -d ' \r\n') || return 1
	version_out=$( grep '^Version:' <<< "$metadatafile" | sed 's|Version:||' | tr -d ' \r\n') || return 1
}
