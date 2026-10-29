prob_bin() {
	# prob_bin $root
	local root=$1 reply selected binName i
	local -a candidates=()

	if root=$(realpath -- "$root"); then :
	else return 1
	fi

	mapfile -d '' -t candidates < <(
		find "$root" -maxdepth 4 -type d -name bin -prune \
			-exec find {} -maxdepth 1 \( -type f -o -type l \) -executable -print0 \; \
			2>/dev/null
	)

	if (( ${#candidates[@]} == 0 )); then
		mapfile -d '' -t candidates < <(
			find "$root" -maxdepth 1 \( -type f -o -type l \) -executable -print0 2>/dev/null
		)
	fi

	if (( ${#candidates[@]} )); then :
	else
		printerr "no executables found"
		return 2
	fi

	if (( ${#candidates[@]} == 1 )); then
		selected=${candidates[0]}
	else
		printerr "more than one executable found, choose one to symlink"
		for i in "${!candidates[@]}"; do
			printf '%2d) %s\n' "$((i + 1))" "${candidates[i]}" >&2
		done

		while true; do
			if read -r -p "[1-${#candidates[@]}], q to quit: " reply; then :
			else return 1
			fi

			if [[ ${reply,,} == q ]]; then return 2
			fi

			if [[ $reply =~ ^[0-9]+$ ]] &&
			   (( 10#$reply >= 1 && 10#$reply <= ${#candidates[@]} )); then
				selected=${candidates[10#$reply - 1]}
				confirmation "you selected $selected" "is that okay? [y/n/q] "
				case $? in
					0) break ;;
					2) continue ;;
					*) return 1 ;;
				esac
			fi
			printerr "Invalid choice"
		done
	fi

	if binName=$(prompt_name); then :
	else return $?
	fi

	if mkdir -p "$HOME/bin"; then :
	else return 1
	fi

	if ln -s -- "$selected" "$HOME/bin/$binName"; then :
	else return 1
	fi

	printf 'linked %s -> %s\n' "$HOME/bin/$binName" "$selected"
}
