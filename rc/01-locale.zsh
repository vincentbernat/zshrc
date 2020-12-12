# -*- sh -*-

(( $+commands[locale] )) && () {
    local -a available
    local -A locales
    local locale
    locales=( "LANG" "C.UTF-8 C.utf8 en_US.UTF-8 en_US.utf8 C"
	      "LC_MESSAGES" "fr_FR.utf8 en_US.UTF-8 en_US.utf8 C.UTF-8 C.utf8 C"
	      "LC_NUMERIC" "en_US.UTF-8 en_US.utf8 C.UTF-8 C.utf8 C" )
    available=("${(f)$(locale -a)}")
    for locale in ${(k)locales}; do
	for l in $=locales[$locale]; do
            if (( ${available[(i)$l]} <= ${#available} )); then
		export $locale=$l
		break
	    fi
	done
    done
    export LC_CTYPE=$LANG
    unset LC_ALL
} 2> /dev/null
