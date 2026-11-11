extract_asset() {
	# call as extract_asset $downloaded_file $empty_staging_dir
	# returns 0 ok, 1 failure, 2 the user declined
	local file_in=$1 dest_in=$2
	local reply filetype base out

	if ! filetype=$(file -ib -- "$file_in"); then
		return 1
	fi
	base=$(basename -- "$file_in")

	case "$filetype" in
		application/zip*)
			if ! command -v unzip >/dev/null; then
				printerr "unzip is needed for .zip assets"
				return 1
			fi
			if ! unzip -q -- "$file_in" -d "$dest_in"; then
				printerr "Extracting $file_in failed"
				return 1
			fi
			;;

		application/gzip*| \
		application/x-bzip2*| \
		application/x-xz*| \
		application/zstd*| \
		application/x-lzip*| \
		application/x-lzma*| \
		application/x-compress*| \
		application/tar*| \
		application/x-tar*)

			# "tar -tf succeeds AND lists something": on streams shorter than one 512 byte block
			# tar exits 0 with no output, which would make a tiny gzipped script look like an empty tarball
			if [[ -n $(tar -tf "$file_in" 2>/dev/null) ]]; then
				if ! tar -xf "$file_in" -C "$dest_in"; then
					printerr "Extracting $file_in failed"
					return 1
				fi
			else
				# a compressed single file (tool-linux-amd64.gz), not a tarball
				out="$dest_in/${base%.*}"
				case "$filetype" in
					application/gzip*)    gzip -dc -- "$file_in" > "$out" || { printerr "gzip failed"; return 1; } ;;
					application/x-bzip2*) bzip2 -dc -- "$file_in" > "$out" || { printerr "bzip2 failed"; return 1; } ;;
					application/x-xz*)    xz -dc -- "$file_in" > "$out" || { printerr "xz failed"; return 1; } ;;
					application/zstd*)    zstd -dc -- "$file_in" > "$out" || { printerr "zstd failed"; return 1; } ;;
					*) printerr "cannot unpack $filetype"; return 1 ;;
				esac
				chmod u+x -- "$out"
			fi
			;;

		application/x-elf*| \
		application/x-pie-executable*| \
		application/x-executable*| \
		application/x-sharedlib*| \
		text/x-shellscript*)
			printf '\nTHIS IS AN EXECUTABLE\n'
			if ! mv -- "$file_in" "$dest_in/$base"; then
				printerr "failed to move $file_in to $dest_in"
				return 1
			fi
			chmod u+x -- "$dest_in/$base"
			return 0
			;;

		*) printf '\nunfamiliar/unsupported type: %s\n' "$filetype" >&2
			while true; do
				read -r -p "install it as it is, without unpacking? (y/n): " reply || return 1
				case "${reply,,}" in
					y)
						if ! mv -- "$file_in" "$dest_in/$base"; then
							printerr "failed to move $file_in to $dest_in"
							return 1
						fi
						return 0
					;;
					n) return 2 ;;
					*) printerr "try again" ;;
				esac
			done
			;;
	esac

	flatten_single_dir "$dest_in"
}

flatten_single_dir() {
	# Many releases unpack to exactly one directory named after the version (tool-1.2.3/...).
	# Left alone, the version ends up in every path we store and every symlink dies on the next update.
	# So: one directory and nothing else -> lift its contents up one level.
	local dir_in=$1 hold
	local -a entries

	shopt -s nullglob dotglob
	entries=("$dir_in"/*)
	shopt -u nullglob dotglob

	(( ${#entries[@]} == 1 )) || return 0
	[[ -d ${entries[0]} && ! -L ${entries[0]} ]] || return 0
	# "bin/" on its own is already the layout we want
	[[ ${entries[0]##*/} == bin ]] && return 0

	# park it in a scratch dir first, so tool/tool/ (same name inside) cannot collide
	hold=$(mktemp -d "$dir_in/.flatten.XXXXXX") || return 1
	mv -- "${entries[0]}" "$hold/x" || return 1

	shopt -s nullglob dotglob
	entries=("$hold/x"/*)
	shopt -u nullglob dotglob

	if (( ${#entries[@]} )); then
		mv -- "${entries[@]}" "$dir_in"/ || return 1
	fi
	rmdir -- "$hold/x" "$hold"
}
