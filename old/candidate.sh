# A "candidate" is one tab separated line: name <TAB> download url <TAB> digest ("-" when github gave none)

find_candidates() {
	# called as: find_candidates "$github_json" [old_asset_name] [predicted_asset_name]
	local github_json_preproc=$1
	local old_name=${2:-} predicted=${3:-}
	local candidates_preproc="" want

	# 1) the asset we installed last time, 2) that same name with the version bumped
	for want in "$old_name" "$predicted"; do
		if [[ -n $want ]]; then
			candidates_preproc=$(return_named_candidate "$want" "$github_json_preproc")
			if [[ -n $candidates_preproc ]]; then break
			fi
		fi
	done

	if [[ -z $candidates_preproc ]]; then
		if ! candidates_preproc=$(filter_find_candidates "$github_json_preproc"); then
			printerr "asset lookup failed"
			return 1
		fi

		if [[ -z $candidates_preproc ]]; then
			printerr "no candidates post filtering, attempting to list all candidates"
			candidates_preproc=$(return_all_candidates "$github_json_preproc")
			if [[ -z "$candidates_preproc" ]]; then
				printerr "nothing"
				return 1
			fi
		fi
	fi

	printf '%s\n' "$candidates_preproc"
}

return_all_candidates() {
	# called as: return_all_candidates $github_json
	local github_json_in=$1
	jq -r '
		(.assets // [])
		| sort_by(.name)[]
		| [.name, .browser_download_url, (.digest // "-")] | @tsv
	' <<< "$github_json_in"
}

return_named_candidate() {
	# called as: return_named_candidate $asset_name $github_json
	local asset_name_in=$1
	local github_json_in=$2
	jq -r --arg name "$asset_name_in" '
		(.assets // [])[]
		| select(.name == $name)
		| [.name, .browser_download_url, (.digest // "-")] | @tsv
	' <<< "$github_json_in"
}

filter_find_candidates() {
	# Called as: filter_find_candidates "$github_json"
	# Instead of whitelisting extensions (which dropped bare binaries, .AppImage, .gz, ...),
	# we drop what is clearly not the program: other OSes, other CPUs, checksums, signatures, packages.
	local github_json_in=$1
	local sep_l='(^|[^[:alnum:]])'
	local sep_r='([^[:alnum:]]|$)'
	local arch_filter="" arch os_filter junk_filter

	if ! arch=$(uname -m); then
		printerr "failed to retrive machine arch"
		return 1
	fi

	case "$arch" in
		x86_64)        arch_filter="${sep_l}(x86[_-]64|amd64|x64|linux64|64-?bit)${sep_r}" ;;
		aarch64|arm64) arch_filter="${sep_l}(aarch64|arm64|armv8)${sep_r}" ;;
		armv7l|armv6l) arch_filter="${sep_l}(armv[67]l?|armhf|arm)${sep_r}" ;;
		*)
			# unknown cpu: do not abort, let the caller show everything and the user decide
			printerr "unknown arch: $arch, showing all assets"
			return 0
			;;
	esac

	os_filter="${sep_l}(darwin|macos|osx|apple|mac|windows|win(32|64)?|msvc|freebsd|openbsd|netbsd|dragonfly|illumos|solaris|android|ios)${sep_r}"
	junk_filter='\.(sha1|sha256|sha512|md5|sig|asc|minisig|pem|crt|cert|pub|sbom|spdx|json|jsonl|intoto|txt|md|deb|rpm|apk|msi|exe|dmg|pkg|nupkg|whl|jar|ps1|7z|rar)$'
	junk_filter+='|(^|[^[:alnum:]])(sha256sums?|checksums?|sbom)([^[:alnum:]]|$)'

	jq -r \
		--arg arch "$arch_filter" \
		--arg os "$os_filter" \
		--arg junk "$junk_filter" '
		[ (.assets // [])[]
		  | select((.name | test($junk; "i")) | not)
		  | select(.name | test($arch; "i"))
		  | select((.name | test($os; "i")) | not)
		] as $c
		# if anything says "linux" (an AppImage is linux by definition), the rest is noise
		| (if any($c[]; .name | test("linux|\\.appimage$"; "i")) then [$c[] | select(.name | test("linux|\\.appimage$"; "i"))] else $c end)
		| sort_by(.name)[]
		| [.name, .browser_download_url, (.digest // "-")] | @tsv
	' <<< "$github_json_in"
}

select_candidate_url() {
	# Called as: select_candidate_url "$candidates" asset_name asset_url asset_digest [trusted_name]
	# trusted_name: when the only candidate is exactly this (an update of what the user already chose) we do not ask again
	# 1 to terminate with error, 2 to terminate with sucess, 0 to carry on
	local candidates_in=$1
	local -n asset_name_out=$2
	local -n asset_url_out=$3
	local -n asset_digest_out=$4
	local trusted_name=${5:-}
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
				if ! read -r -p "Pick an asset [1-${#lines[@]}], q to quit: " reply; then
					return 1
				fi
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
		IFS=$'\t' read -r asset_name_out asset_url_out asset_digest_out <<< "$selected"

		if (( ${#lines[@]} == 1 )) && [[ -n $trusted_name && $asset_name_out == "$trusted_name" ]]; then
			printf 'asset: %s\n' "$asset_name_out"
			return 0
		fi

		while true; do
			if ! read -r -p "Selected asset: $asset_name_out. Is that correct? [y/n/q] " reply; then
				return 1
			fi

			case "${reply,,}" in
				y) return 0 ;;
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
