install_from_url() {
	#called as: install_from_url "$url"
	local url=$1
	local owner project github_json latversion candidates dir asset_name asset_url reply status=0

	if ! parse_github_url "$url" owner project; then
		return 1
	fi

	if ! github_json=$(fetch_latest "$owner" "$project"); then
		printerr "$project: no response from github"
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

	if select_candidate_url "$candidates" asset_name asset_url; then :
	else
		status=$?
		[[ $status -eq 2 ]] && return 0
		return 1
	fi

	local program_path="$programs_dir/$project"."$owner"
	if ! mkdir "$program_path" 2>/dev/null; then
		if ! [[ -d "$programs_dir" ]]; then
			printerr "parent folder $programs_dir is not found"
			return 1
		fi

		printf 'Establishing a New Home For the Program Failed Due To Collision\n%s Exits\n' "$program_path"
		printf 'Should it Be Used Anyway? All Contens Inside will be removed..'
		while true; do
			if ! read -r -p "[y/n]?" reply; then
				return 1
			fi
			case ${reply,,} in
				y)
					break
				;;
				n) return 0;;
				*) printerr "unkown input";;
			esac
		done
	fi

	if ! install "$asset_name" "$asset_url" "$program_path" "$owner" "$project" "$latversion"; then
		status=1
	fi

	return "$status"
}

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
