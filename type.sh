type_reslution() {
	# call as type_reslution $oldpath $newpath
	local temppath_in=$1
	local newpath_in=$2
	local reply filetype

	if ! filetype=$(file -ib "$temppath"); then
		return 1
	fi

	case "$filetype" in
			application/gzip*| \
			application/x-bzip2*| \
			application/x-xz*| \
			application/zstd*| \
			application/x-lzip*| \
			application/x-lzma*| \
			application/x-compress*| \
			application/zip*| \
			application/tar*)

			if ! tar -xf "$temppath" -C "$newpath"; then
				printerr "Extracting $temppath failed"
				return 1
			fi

			;;
		*) printerr "unfamiliar type: $Aname";
			while true; do
				read -r -n 1 -p "This Package will be removed, unlesss you want to install it as it ? (y/n): " reply || return 1
				case "${reply,,}" in
					"y")
						if ! mv "$temppath_in" "$newpath_in"; then
							printerr "failed to move $temppath_in to $newpath_in"
							return 1
						fi
					break
					;;
					"n") return 1;;
					*) printerr "try again";;
				esac
			done
			;;
	esac
}
