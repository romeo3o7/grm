resolve_program() {
	# resolve_program <name> <outvar>
	# accepts "tool.owner" or just "tool" when that is unambiguous. Names with '/' are refused,
	# so nothing outside $programs_dir can be reached.
	local name_in=$1
	local -n path_out=$2
	local hit
	local -a hits

	if [[ -z $name_in || $name_in == */* || $name_in == .* ]]; then
		printerr "bad package name: '$name_in'"
		return 1
	fi

	if [[ -d $programs_dir/$name_in ]]; then
		path_out="$programs_dir/$name_in"
		return 0
	fi

	shopt -s nullglob
	hits=("$programs_dir/$name_in".*/)
	shopt -u nullglob

	case ${#hits[@]} in
		0) printerr "no such package: $name_in"; return 1 ;;
		1) path_out=${hits[0]%/}; return 0 ;;
		*)
			printerr "'$name_in' is ambiguous, say which one:"
			for hit in "${hits[@]}"; do printerr "  $(basename -- "${hit%/}")"; done
			return 1
			;;
	esac
}

link_package() {
	# link_package <name>: add (or re-point) one more symlink into an installed package
	local program_path owner project version asset entry lname i
	local -a links kept=()

	resolve_program "$1" program_path || return 1
	if ! read_metadata "$program_path" owner project version asset links; then
		printerr "not a grm package (no usable metadata)"
		return 1
	fi

	if ! choose_link "$program_path" "$program_path" "$project" entry; then
		return 1
	fi

	# a name can only point at one binary: drop an older entry with the same name
	lname=${entry%%:*}
	for i in "${links[@]}"; do
		if [[ ${i%%:*} != "$lname" ]]; then kept+=("$i")
		fi
	done
	kept+=("$entry")

	write_metadata "$program_path" "$owner" "$project" "$version" "$asset" kept || return 1
	link_one "$program_path" "$entry"
}

remove_package() {
	# remove_package <name>
	local program_path reply target
	local owner project version asset
	local -a links

	resolve_program "$1" program_path || return 1
	# belt and braces: never rm -rf anything that is not strictly inside $programs_dir
	if [[ $program_path != "$programs_dir"/?* ]]; then
		printerr "refusing to remove $program_path"
		return 1
	fi

	if read_metadata "$program_path" owner project version asset links 2>/dev/null; then
		printf 'remove %s (%s)\n' "${program_path##*/}" "$version"
	else
		printf 'remove %s (no metadata)\n' "${program_path##*/}"
	fi

	while true; do
		if ! read -r -p "This deletes $program_path and the symlinks into it. Continue? [y/n] " reply; then
			return 1
		fi
		case ${reply,,} in
			y) break ;;
			n) return 0 ;;
			*) printerr "unkown input" ;;
		esac
	done

	# every symlink in bin_dir that points inside the package, whether or not metadata knew about it
	for target in "$bin_dir"/*; do
		if [[ -L $target && $(readlink -- "$target") == "$program_path"/* ]]; then
			rm -- "$target" && printf 'removed link %s\n' "$target"
		fi
	done

	rm -rf -- "$program_path"
	printf 'removed %s\n' "$program_path"
}
