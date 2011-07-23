# -*- sh -*-

(( $+commands[cowbuilder] )) && {
    _vbe_cowbuilder() { 
        local distrib=$1
        shift
        local opts=""
        local target=$distrib
        [[ -n $ARCH ]] && {
            target=$distrib-$ARCH
            opts="--debootstrapopts --arch --debootstrapopts $ARCH"
            export DEBIAN_BUILDARCH="$ARCH"
        }
	_vbe_title "cowbuilder-$distrib: $@"
        sudo cowbuilder "$@" --distribution $distrib  \
            --basepath /var/cache/pbuilder/base.$target.cow \
            --buildresult /var/cache/pbuilder/result-$target \
            ${=opts}
    }
    alias cowbuilder-squeeze='_vbe_cowbuilder squeeze'
    alias cowbuilder-lenny='_vbe_cowbuilder lenny'
    alias cowbuilder-etch='_vbe_cowbuilder etch'
}
