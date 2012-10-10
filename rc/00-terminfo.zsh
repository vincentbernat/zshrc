# -*- sh -*-

# Update terminfo
__() {
    local terminfo
    local termpath
    for terminfo in $ZSH/terminfo/*.terminfo(.N); do
	# We assume that the file is named appropriately for this to work
	termpath=~/.terminfo/${(@)${terminfo##*/}[1]}/${${terminfo##*/}%%.terminfo}
	if [[ ! -e $termpath ]] || [[ $terminfo -nt $termpath ]]; then
	    TERMINFO=~/.terminfo tic $terminfo
	fi
    done
} && __

# Update TERM if we have LC__ORIGINALTERM variable
__() {
    [[ -z $LC__ORIGINALTERM ]] || [[ $LC__ORIGINALTERM = $TERM ]] || {
        local locs loc
        locs=( $TERMINFO ~/.terminfo $TERMINFO_DIRS /usr/{,share/}{,lib/}terminfo )
        for loc in $locs; do
            [[ -e $loc/${(@)${LC__ORIGINALTERM}[1]}/${LC__ORIGINALTERM} ]] || continue
            export TERM=$LC__ORIGINALTERM
            unset LC__ORIGINALTERM
            break
        done
    }
} && __

autoload -U colors zsh/terminfo
[[ "$terminfo[colors]" -ge 8 ]] && colors
