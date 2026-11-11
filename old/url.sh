install_from_url() {
	#called as: install_from_url "$url"
	local url=$1
	local owner project github_json latversion candidates asset_name asset_url asset_digest reply program_path rc
	local old_owner old_project old_version old_asset
	local -a links=()

	if ! parse_github_url "$url" owner project; then
		return 1
	fi

	if ! github_json=$(fetch_latest "$owner" "$project"); then
		return 1
	fi

	latversion=$(jq -r '.tag_name // empty' <<< "$github_json")
	if [[ -z "$latversion" ]]; then
		printerr "$project: can't find version ~empty json"
		return 1
	fi

	if ! candidates=$(find_candidates "$github_json"); then
		return 1
	fi

	rc=0
	select_candidate_url "$candidates" asset_name asset_url asset_digest || rc=$?
	case $rc in
		0) ;;
		2) return 0 ;;
		*) return 1 ;;
	esac

	program_path="$programs_dir/$project.$owner"

	# nothing is created or deleted here any more: the old copy stays until the new one is complete
	if [[ -e $program_path || -L $program_path ]]; then
		printf '%s already exists. It is kept until the new copy is ready, then replaced.\n' "$program_path"
		if ! confirmation "Replace it?" "[y/n]"; then
			return 0
		fi

		# a reinstall keeps the links the package already had
		read_metadata "$program_path" old_owner old_project old_version old_asset links 2>/dev/null || links=()
	fi

	rc=0
	install_package "$asset_name" "$asset_url" "$asset_digest" "$program_path" "$owner" "$project" "$latversion" links || rc=$?
	case $rc in
		0) return 0 ;;
		2) printf 'cancelled, nothing was changed\n'; return 0 ;;
		*) return 1 ;;
	esac
}

parse_github_url() {
	# called as: parse_github_url "$url" owner project
	local url_in=$1
	local -n owner_out=$2
	local -n project_out=$3
	local rest o p extra

	case "$url_in" in
		https://github.com/*) rest=${url_in#https://github.com/} ;;
		*) printerr "not github url"; return 1 ;;
	esac

	rest=${rest%%[?#]*}    # drop ?query and #fragment
	rest=${rest%/}         # drop one trailing slash
	IFS=/ read -r o p extra <<< "$rest"
	p=${p%.git}            # https://github.com/owner/repo.git

	[[ -n $o && -n $p ]] || { printerr "url has no owner/repo"; return 1; }
	case "$o" in *[!A-Za-z0-9._-]*) printerr "bad owner name"; return 1 ;; esac
	case "$p" in *[!A-Za-z0-9._-]*) printerr "bad repo name"; return 1 ;; esac
	[[ $o == . || $o == .. || $p == . || $p == .. ]] && { printerr "bad name"; return 1; }

	# github ignores case, so Foo/Tool and foo/tool must land in the same directory
	owner_out=${o,,}
	project_out=${p,,}
}
