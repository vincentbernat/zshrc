# -*- sh -*-

(( $+commands[locale] )) && function {
    local locales
    locales=( "LANG fr_FR.utf8 en_US.utf8 C.UTF-8 C" \
	      "LC_MESSAGES en_US.utf8 fr_FR.utf8 C.UTF-8 C" )
    for locale in $locales; do
	for l in $=locale[(w)2,-1]; do
	    if locale -a | grep -qx $l; then
		export $locale[(w)1]=$l
		break
	    fi
	done
    done
} 2> /dev/null
