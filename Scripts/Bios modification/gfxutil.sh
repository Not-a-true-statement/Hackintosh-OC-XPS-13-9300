# joevt May 30, 2020

gfxutilcmd="/Volumes/Work/Programming/EFIProjects/gfxutil-1.80b_joevt3/DerivedData/gfxutil/Build/Products/Release/gfxutil"

alias gfxutil="'$gfxutilcmd'"
export UBSAN_OPTIONS="suppressions=/Volumes/Work/Programming/EFIProjects/gfxutil-1.80b_joevt3/gfxutilUBSan.supp"

nvramp () {
	local thename="$1"
	local thedata="" # must declare local separately for $? to get the error
	thedata="$(nvram $thename)"
	local theerr=$?
	printf "$(sed -E '/^'$thename'./s///;s/\\/\\\\/g;s/%/\\x/g' <<< "$thedata")"
	return $theerr
}

bootvar () {
	local thebootvar=$1
	local thebytes="$(nvramp 8BE4DF61-93CA-11D2-AA0D-00E098032B8C:"$thebootvar" | xxd -p -c 99999; echo ${pipestatus[1]}${PIPESTATUS[0]})"
	local theerr=$(sed -n \$p <<< "$thebytes")
	if (( !$theerr )); then
		thebytes=$(sed \$d <<< "$thebytes")
		local theflag=$((0x${thebytes:6:2}${thebytes:4:2}${thebytes:2:2}${thebytes:0:2}))
		local thepathlength=$((0x${thebytes:10:2}${thebytes:8:2}))
		local thestring=$(xxd -p -r <<< "${thebytes:12}" | iconv -f UTF-16LE -t UTF-8 | tr '\0' '\n' | sed -n -E '1p' | tr -d '\n')
		local thepath=${thebytes:12 + (${#thestring}+1) * 4:$thepathlength*2}
		local theoptions=${thebytes:12 + (${#thestring}+1) * 4 + ${#thepath}}
		local theoptionsstring=$(xxd -p -r <<< "${theoptions}" | iconv -f UTF-16LE -t UTF-8 | tr '\0' '\n' | sed -n -E '1p' | tr -d '\n')
		echo -n "$thebootvar: $theflag, "'"'"$thestring"'"'
		[[ -n $thepath ]] && { echo -n ', "'; gfxutil "$thepath"; echo -n '"'; }
		[[ -n $theoptions ]] && echo -n ", "'"'"$theoptionsstring"'"'
		echo
		local bytesremaining=$((${#thebytes}/2 - 6 - (${#thestring}+1)*2 - thepathlength - (${#theoptions} > 0) * (${#theoptionsstring}+1)*2 ))
		if (( bytesremaining != 0 )); then
			echo "bytes remaining: $bytesremaining"
		fi
	fi
	return $theerr
}

dumpallbootvars () {
	printf "BootOrder: "
	nvramp 8BE4DF61-93CA-11D2-AA0D-00E098032B8C:BootOrder | xxd -p -c 99999 | sed -E 's/(..)(..)/Boot\2\1 /g'
	((boot=0))
	while bootvar Boot$(printf "%04x" $boot) 2> /dev/null; do
		((boot++))
	done
	((boot=0x80))
	while bootvar Boot$(printf "%04x" $boot) 2> /dev/null; do
		((boot++))
	done
	((boot=0xffff))
	while bootvar Boot$(printf "%04x" $boot) 2> /dev/null; do
		((boot--))
	done
}

dumpallioregefipaths () {
	eval "$(
		(ioreg -lw0 -p IODeviceTree; ioreg -lw0) | perl -e '
		$thepath=""; while (<>) {
			if ( /^([ |]*)\+\-o (.+)  </ ) { $indent = (length $1) / 2; $name = $2; $thepath =~ s|^((/[^/]*){$indent}).*|$1/$name| }
			if ( /^[ |]*"([^"]+)" = <(.*7fff0400.*)>/i ) { print $thepath . "/" . $1 . " = <" . $2 . ">\n" }
		}
		' | sed -E '/device-properties/d;/(.*) = <(.*)>/s//echo -n "\1 = "; gfxutil \2; echo/'
	)"
}

ioregp () {
	ioreg -n "$2" -w0 -p "$1" -k "$3" | sed -nE 's/^[ |]+"'"$3"'" = <(.*)>/\1/p' | xxd -p -r
}


getdeviceprops () {
	ioreg -rw0 -p IODeviceTree -n efi | grep device-properties | sed 's/.*<//;s/>.*//;' | xxd -p -r
}

getaaplpathprops () {
	# Get device properties from nvram AAPL,PathProperties0000,0001,etc.
	# (max 768 per nvram var)
	i=0
	while (( 1 )); do
		thevar="4D1EDE05-38C7-4A6A-9CC6-4BCCA8B38C14:AAPL,PathProperties$(printf "%04X" $i)"
		theval="$(nvram "$thevar" 2> /dev/null)"
		[[ -z $theval ]] && break
		printf "$(echo -n "$theval" | sed -E '/^'$thevar'./s///;s/\\/\\\\/g;s/%/\\x/g')"
		((i++))
	done
}

setaaplpathprops () {
	local thefile="$1"
	local theproperties=$(xxd -p -c 99999 "$1")
	local thevar=0
	while ((1)); do
		local thepart=${theproperties:$thevar*768*2:768*2}
		local thename="4D1EDE05-38C7-4A6A-9CC6-4BCCA8B38C14:AAPL,PathProperties"$(printf "%04X" thevar)
		if [[ -n $thepart ]]; then
			sudo nvram "${thename}=$(sed -E 's/(..)/%\1/g' <<< ${thepart})"
		else
			nvram "${thename}" > /dev/null 2>&1 && sudo nvram -d "$thename" || break
		fi
		((thevar++))
	done
}

getpanic () {
	# Get device properties from nvram AAPL,PanicInfo000K,000M,etc.
	# (max 768 per nvram var)
	i=0
	while (( 1 )); do
		thevar="AAPL,PanicInfo000$(printf "%02x" $((0x$(printf 'K' | xxd -p) + i)) | xxd -p -r)"
		theval="$(nvram "$thevar" 2> /dev/null)"
		[[ -z $theval ]] && break
		printf "$(echo -n "$theval" | sed -E '/^'$thevar'./s///;s/\\/\\\\/g;s/%/\\x/g')"
		((i++))
	done
}

getpanic2 () {
	# Get device properties from nvram aapl,panic-info
	# (max 768 per nvram var)
	i=0
	while (( 1 )); do
		thevar="aapl,panic-info"
		theval="$(nvram "$thevar" 2> /dev/null)"
		[[ -z $theval ]] && break
		printf "$(echo -n "$theval" | sed -E '/^'$thevar'./s///;s/\\/\\\\/g;s/%/\\x/g')"
		((i++))
		break
	done
}

#GfxUtilphp="/Volumes/Work/Programming/ThunderboltProjects/Other/OSXOLVED/OSXOLVED-master joevt2/yod-GfxUtil.php"
#alias yod-GfxUtil.php="'$GfxUtilphp'"
#bbedit "$GfxUtilphp"
#[[ -f "$GfxUtilphp" ]] && xattr -l "$GfxUtilphp" | grep -q "com.apple.quarantine:" && xattr -d com.apple.quarantine "$GfxUtilphp"
