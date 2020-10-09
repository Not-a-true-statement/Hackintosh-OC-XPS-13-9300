[[ -f ~/Downloads/gfxutil.sh ]] && source ~/Downloads/gfxutil.sh

# https://github.com/Not-a-true-statement/OC-XPS-13-9300
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
		echo -n "${theflags}${thevar}" | xxd -p -r > "/sys/firmware/efi/efivars/${thevarname}-${thevarguid}"
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

getvar B08F97FF-E6E8-4193-A997-5E9E9B0ADB32:CpuSetup # VarStore 0x3

echo -n "${theflags}${thevar}" | xxd -p -r > ~/Downloads/SetupVar_before.bin
echo 'flags:"'$theflags'"'

echo before 0x4B:$(dumpbyte 0x4B) # expect 0xFF = C State auto 
echo before 0x43:$(dumpbyte 0x43) # expect 0x01 = CFG Lock enabled
setbyte 0x43 0x0 # CFG Lock disabled
echo after 0x43:$(dumpbyte 0x43)
echo -n "${theflags}${thevar}" | xxd -p -r > ~/Downloads/SetupVar_after.bin

echo diffs:
eval $(cmp -l ~/Downloads/SetupVar_before.bin ~/Downloads/SetupVar_after.bin | perl -nE '/(\d+) *(\d+) *(\d+)/ && print "echo \$(printf 0x%08x \$((10#" . $1 . " - 1))) \$(printf 0x%02x \$((8#" . $2 . "))) \$(printf 0x%02x \$((8#" . $3 . ")))\n"')

#=========

#putvar