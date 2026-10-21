filter_find_candidates() {
	# Called as: filter_find_candidates "$github_json"
	local github_json_in=$1
	local sep_l='(^|[^[:alnum:]])'
	local sep_r='([^[:alnum:]]|$)'
	local arch_filter arch os_filter ext_filter

	arch=$(uname -m) || return 1

	case "$arch" in
		x86_64)  arch_filter="${sep_l}(x86_64|amd64|x64)${sep_r}" ;;
		aarch64) arch_filter="${sep_l}(aarch64|arm64)${sep_r}" ;;
		*)
			printerr "unsupported arch: $arch"
			return 1
			;;
	esac

	os_filter="${sep_l}(darwin|macos|osx|apple|mac|windows|win(32|64)?|msvc|freebsd|openbsd|netbsd|dragonfly|illumos|solaris|android|ios)${sep_r}"
	ext_filter='\.tar\.(gz|xz|zst|bz2)$|\.tgz$|\.zip$'

	jq -r \
		--arg arch "$arch_filter" \
		--arg ext "$ext_filter" \
		--arg os "$os_filter" '
		.assets[]
		| select(.name | test($ext; "i"))
		| select(.name | test($arch; "i"))
		| select((.name | test($os; "i")) | not)
		| [.name, .browser_download_url] | @tsv
	' <<< "$github_json_in"
}

select_candidate_url() {
	# Called as: select_candidate_url "$candidates" asset_name asset_url
	local candidates_in=$1
	local -n asset_name_out=$2
	local -n asset_url_out=$3
	local -a lines
	local i reply choice selected

	mapfile -t lines <<< "$candidates_in"

	while true; do
		if (( ${#lines[@]} == 1 )); then
			choice=0
		else
			for i in "${!lines[@]}"; do
				printf '%2d) %s\n' "$((i + 1))" "${lines[i]%%$'\t'*}" >&2
			done

			while true; do
				read -r -p "Pick an asset [1-${#lines[@]}], q to quit: " reply || return 1
				case "${reply,,}" in
					q) return 2 ;;
				esac

				if [[ $reply =~ ^[0-9]+$ ]] &&
				   (( 10#$reply >= 1 && 10#$reply <= ${#lines[@]} )); then
					choice=$((10#$reply - 1))
					break
				fi
				printerr "Invalid choice"
			done
		fi

		selected=${lines[choice]}
		asset_name_out=${selected%%$'\t'*}

		while true; do
			read -r -p "Selected asset: $asset_name_out. Is that correct? [y/n/q] " reply || return 1

			case "${reply,,}" in
				y)
					asset_url_out=${selected#*$'\t'}
					return 0
					;;
				n)
					if (( ${#lines[@]} == 1 )); then
						printerr "Selection cancelled"
						return 2
					fi
					break
					;;
				q) return 2 ;;
				*) printerr "Please enter y, n, or q." ;;
			esac
		done
	done
}
