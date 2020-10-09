[[ -f ~/Downloads/gfxutil.sh ]] && source ~/Downloads/gfxutil.sh

getvar () {
	thevar=""
	theflags=""
	thevarname=$1
	thevarguid=${thevarname%:*}
	thevarname=${thevarname#*:}

	if [[ -d /sys/firmware/efi/efivars ]]; then
		thevar=$(xxd -p -c 99999999 "/sys/firmware/efi/efivars/${thevarname}-${thevarguid}")
		theflags=${thevar:0:8}
		thevar=${thevar:8}
	else
		thevar=$(nvramp ${thevarguid}:${thevarname} | xxd -p -c 99999999)
	fi
}

putvar () {
	if [[ -d /sys/firmware/efi/efivars ]]; then
		sudo xxd -p -r > "/tmp/${thevarname}-${thevarguid}" <<< "${theflags}${thevar}"
	else
		sudo nvram "${thevarguid}:${thevarname}=$(sed -E 's/(..)/%\1/g' <<< ${thevar})"
	fi
}

dumpbyte () {
	local theoffset=$1
	echo 0x${thevar:$((theoffset * 2)):2}
}

setbyte () {
	local theoffset=$1
	local thebyte=$(printf "%02x" $(($2)))
	thevar=${thevar:0:$((theoffset * 2))}${thebyte}${thevar:$((theoffset * 2 + 2))}
}

#=========

getvar 72C5E28C-7783-43A1-8767-FAD73FCCAFA4:SaSetup

echo -n "${theflags}${thevar}" | xxd -p -r > ~/SetupVar_before.bin
echo 'flags:"'$theflags'"'

echo before 0xA4:$(dumpbyte 0xA4) # expect 0xfe = 60M
echo before 0xA5:$(dumpbyte 0xA5) # expect 0x02 = 256M
setbyte 0xA4 0x4 # 128M
echo after 0xA4:$(dumpbyte 0xA4)
echo -n "${theflags}${thevar}" | xxd -p -r > ~/SetupVar_after.bin

echo diffs:
eval $(cmp -l ~/SetupVar_before.bin ~/SetupVar_after.bin | perl -nE '/(\d+) *(\d+) *(\d+)/ && print "echo \$(printf 0x%08x \$((10#" . $1 . " - 1))) \$(printf 0x%02x \$((8#" . $2 . "))) \$(printf 0x%02x \$((8#" . $3 . ")))\n"')

#=========

#putvar