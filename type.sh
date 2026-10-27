type_reslution() {
	# call as type_reslution $oldpath $newpath
	local temppath_in=$1
	local newpath_in=$2
	local reply filetype binpath

	if ! filetype=$(file -ib "$temppath_in"); then
		return 1
	fi

	case "$filetype" in
		application/zip*)
            if ! unzip -q "$temppath_in" -d "$newpath_in"; then
                printerr "Extracting $temppath_in failed"
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

			if ! tar -xf "$temppath_in" -C "$newpath_in"; then
				printerr "Extracting $temppath_in failed"
				return 1
			fi
			;;

		application/x-elf*| \
		application/x-pie-executable*| \
		application/x-executable*)
			printf '\nTHIS IS AN EXECUTABLE\n'
			if ! mv "$temppath_in" "$newpath_in"; then
				printerr "failed to move $temppath_in to $newpath_in"
				return 1
			fi
			return 0
			;;

		*) printf '\nunfamiliar type\n' >&2;
			while true; do
				read -r -n 1 -p "This Package will be removed, unlesss you want to install it as it. install? (y/n): " reply || return 1
				case "${reply,,}" in
					"y")
						if ! mv "$temppath_in" "$newpath_in"; then
							printerr "failed to move $temppath_in to $newpath_in"
							return 1
						fi
						return 0
					;;
					"n") return 1;;
					*) printerr "try again";;
				esac
			done
			;;
	esac
}
