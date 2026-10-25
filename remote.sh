parse_github_url() {
	# called as: parse_github_url "$url" owner project
	local url_in=$1
	local -n owner_out=$2
	local -n project_out=$3
	local rest o p extra

	case "$url_in" in
		https://github.com/*) rest=${url_in#https://github.com/} ;;
		*) printerr "not a https://github.com/ url"; return 1 ;;
	esac

	rest=${rest%%[?#]*}    # drop ?query and #fragment
	rest=${rest%/}         # drop one trailing slash
	IFS=/ read -r o p extra <<< "$rest"
	p=${p%.git}            # https://github.com/owner/repo.git

	[[ -n $o && -n $p ]] || { printerr "url has no owner/repo"; return 1; }
	case "$o" in *[!A-Za-z0-9._-]*) printerr "bad owner name"; return 1 ;; esac
	case "$p" in *[!A-Za-z0-9._-]*) printerr "bad repo name"; return 1 ;; esac
	[[ $o == . || $o == .. || $p == . || $p == .. ]] && { printerr "bad name"; return 1; }

	owner_out=$o
	project_out=$p
}

install_from_url() {
	#called as: install_from_url "$url"
	local url=$1
	local owner project github_json latversion candidates dir asset_name asset_url status rc=0
	local temp="" newpath=""

	parse_github_url "$url" owner project || return 1

	github_json=$(fetch_latest "$owner" "$project") || {
		printerr "$project: no response from github"
		return 1
	}

	latversion=$(jq -r '.tag_name // empty' <<< "$github_json")
	[[ -z "$latversion" ]] && { printerr "$project: can't find version ~empty json"; return 1; }

	candidates=$(find_candidates "$github_json") || return 1

	select_candidate_url "$candidates" asset_name asset_url || {
		status=$?
		[[ $status -eq 2 ]] && return 0
		return 1
	}

	local program_path="$programs_dir/$project"."$owner"
	mkdir "$program_path" || {
		printerr "Creating a new path for the program failed,Rename/Delete $program_path and run script again"
		return 1
	}

	install "$asset_name" "$asset_url" "$program_path" "$owner" "$project" "$latversion" || rc=1

	if [[ -n $temp ]]; then rm -rf "$temp"; fi
	if [[ -n $newpath ]]; then rm -rf "$newpath"; fi

	return "$rc"
}
