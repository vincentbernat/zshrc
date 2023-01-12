# -*- sh -*-

(( $+commands[locale] )) && () {
  local -a available
  local -A locales
  local locale l
  locales=(
    "LANG" "en_US C"
	  "LC_MESSAGES" "en_US C"
    "LC_TIME" "C"
	  "LC_NUMERIC" "en_US C"
  )
  available=("${(f)$(locale -a)}")
  for locale in ${(k)locales}; do
    export $locale=C        # default value
	  for l in $=locales[$locale]; do
      for charset in UTF-8 utf8; do
        if (( ${available[(i)$l.$charset]} <= ${#available} )); then
          export $locale=$l.$charset
          break 2
	      fi
      done
	  done
  done
  export LC_CTYPE=$LANG
} 2> /dev/null
