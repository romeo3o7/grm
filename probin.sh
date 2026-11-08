select_binary() {
	# select_binary $root outvar
	# sets outvar to the chosen executable's path RELATIVE to root (that is what we store,
	# so the link can be rebuilt after every update). returns 0 ok, 1 error, 2 cancelled, 3 none found
	local root=$1 reply selected i path
	local -n rel_out=$2
	local -a found=() candidates=()

	if ! root=$(realpath -- "$root"); then
		return 1
	fi

	# sort -z: find returns directory order, we want a menu that looks the same every time
	mapfile -d '' -t found < <(
		find "$root" -maxdepth 4 -type d -name bin -prune \
			-exec find {} -maxdepth 1 \( -type f -o -type l \) -executable -print0 \; \
			2>/dev/null | sort -z
	)

	if (( ${#found[@]} == 0 )); then
		mapfile -d '' -t found < <(
			find "$root" -maxdepth 2 -type f -executable -print0 2>/dev/null | sort -z
		)
	fi

	for path in "${found[@]}"; do
		candidates+=("${path#"$root"/}")
	done

	if (( ${#candidates[@]} == 0 )); then
		printerr "no executables found"
		return 3
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
				if confirmation "you selected $selected" "is that okay? [y/n/q] "; then i=0
				else i=$?
				fi
				case $i in
					0) break ;;
					2) continue ;;
					3) return 2 ;;
					*) return 1 ;;
				esac
			fi
			printerr "Invalid choice"
		done
	fi

	rel_out=$selected
}

choose_link() {
	# choose_link $root $final_program_path $default_name outvar
	# asks which binary and which link name; outvar becomes "linkname:relative/path".
	# Nothing on disk is touched here, so cancelling is free.
	local root=$1 final=$2 default=$3 rel name
	local -n entry_out=$4

	if select_binary "$root" rel; then :
	else return $?
	fi

	if name=$(prompt_name "$default" "$final"); then :
	else return $?
	fi

	entry_out="$name:$rel"
}

link_one() {
	# link_one $program_path "linkname:relative/path"
	local program_path_in=$1 entry=$2 name rel target
	name=${entry%%:*}
	rel=${entry#*:}
	target="$bin_dir/$name"

	if ! mkdir -p -- "$bin_dir"; then
		printerr "cannot create $bin_dir"
		return 1
	fi

	# replace our own old symlink, but never clobber a real file
	if [[ -e $target && ! -L $target ]]; then
		printerr "$target exists and is not a symlink, leaving it alone"
		return 1
	fi

	if ! ln -sfn -- "$program_path_in/$rel" "$target"; then
		return 1
	fi

	printf 'linked %s -> %s/%s\n' "$target" "$program_path_in" "$rel"
}
