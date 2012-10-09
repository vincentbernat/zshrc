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

# Update TERM if we have ORIGINALTERM variable
__() {
    [[ -z $ORIGINALTERM ]] || [[ $ORIGINALTERM = $TERM ]] || {
        local -a terms
        local term
        terms=( ${(f)"$(toe -a)}"} )
        for term in $terms; do
            [[ ${term%%[[:blank:]]*} = $ORIGINALTERM ]] || continue
            export TERM=$ORIGINALTERM
            unset ORIGINALTERM
            break
        done
    }
} && __

autoload -U colors zsh/terminfo
[[ "$terminfo[colors]" -ge 8 ]] && colors
