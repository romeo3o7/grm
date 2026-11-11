prefetch_releases() {
	# prefetch_releases $outdir
	# one background request per package (at most 6 at once) instead of a serial 15s-timeout walk.
	# results land in $outdir/<package>.json, errors in $outdir/<package>.err
	local outdir=$1 dir owner project version asset name n=0
	local -a links

	for dir in "$programs_dir"/*/; do
		dir=${dir%/}
		read_metadata "$dir" owner project version asset links 2>/dev/null || continue
		name=${dir##*/}
		# ( ) subshell: bash resets our EXIT trap there, so a child can never run cleanup
		( fetch_latest "$owner" "$project" > "$outdir/$name.json" 2> "$outdir/$name.err" ) &
		n=$((n + 1))
		if (( n >= 6 )); then
			wait -n || true
			n=$((n - 1))
		fi
	done
	wait || true
}

list_outdated() {
	local dir owner project version asset latest name found=0
	local -a links

	api_tmp=$(mktemp -d) || return 1
	prefetch_releases "$api_tmp"

	for dir in "$programs_dir"/*/; do
		dir=${dir%/}
		read_metadata "$dir" owner project version asset links 2>/dev/null || continue
		name=${dir##*/}
		found=1
		latest=$(jq -r '.tag_name // empty' "$api_tmp/$name.json" 2>/dev/null || true)
		if [[ -z $latest ]]; then
			printf '%s: %s (could not check)\n' "$name" "$version"
		elif [[ $latest == "$version" ]]; then
			printf '%s: %s up to date\n' "$name" "$version"
		else
			printf '%s: %s -> %s\n' "$name" "$version" "$latest"
		fi
	done
	if (( ! found )); then printerr "no packages installed"
	fi
}

update_all() {
	local dir failures=0 name

	api_tmp=$(mktemp -d) || return 1
	printf 'checking for new releases...\n'
	prefetch_releases "$api_tmp"

	print_lines
	for dir in "$programs_dir"/*/; do
		dir=${dir%/}
		if ! [[ -f $dir/metaGRMfile ]]; then
			continue
		fi
		name=${dir##*/}
		if ! update_one "$dir" "$api_tmp/$name"; then
			failures=$((failures + 1))
		fi
		print_lines
	done

	if (( failures > 0 )); then
		printerr "$failures program(s) failed"
		return 1
	fi
}

update_one() {
	# called as: update_one "$dir" [prefetched_basename]
	# prefetched_basename = path without extension of the .json/.err pair written by prefetch_releases
	local program_path=${1%/}
	local prefetched=${2:-}
	local owner project perversion latversion github_json candidates predicted
	local asset_name asset_url asset_digest reply rc
	local -a links

	if ! read_metadata "$program_path" owner project perversion asset_name links; then
		printerr "read_metadata: existing metadata lookup"
		return 1
	fi

	printf '%s: querying for latest release, current: %s\n' "$project" "$perversion"

	if [[ -n $prefetched ]]; then
		github_json=$(cat -- "$prefetched.json" 2>/dev/null || true)
		if [[ -z $github_json ]]; then
			cat -- "$prefetched.err" >&2 2>/dev/null || true
			printerr "$project: no response from github"
			return 1
		fi
	elif ! github_json=$(fetch_latest "$owner" "$project"); then
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

	# asset names usually carry the version: tool-1.0.0-linux.tgz -> tool-1.0.1-linux.tgz
	predicted=${asset_name//"${perversion#v}"/"${latversion#v}"}

	if ! candidates=$(find_candidates "$github_json" "$asset_name" "$predicted"); then
		return 1
	fi

	rc=0
	select_candidate_url "$candidates" asset_name asset_url asset_digest "$predicted" || rc=$?
	case $rc in
		0) ;;
		2) return 0 ;;
		*) return 1 ;;
	esac

	rc=0
	install_package "$asset_name" "$asset_url" "$asset_digest" "$program_path" "$owner" "$project" "$latversion" links || rc=$?
	cleanup_install

	case $rc in
		0) return 0 ;;
		2) printf 'cancelled, nothing was changed\n'; return 0 ;;
		*) return 1 ;;
	esac
}
