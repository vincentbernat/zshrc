# -*- sh -*-

# Cowbuilder + multistrap
(( $+commands[cowbuilder] )) && {
    _vbe_cowbuilder() {
	# Distribution. Something like debian/squeeze
        local distrib=$1
	# Architecture (optional)
	local arch=${2:-$(dpkg --print-architecture)}
	shift 2

        local opts="--debootstrapopts --arch --debootstrapopts $arch"
	case $distrib in
	    debian/*)
		opts="$opts --mirror http://ftp.fr.debian.org/debian"
		opts="$opts --debootstrapopts --keyring --debootstrapopts /usr/share/keyrings/debian-archive-keyring.gpg"
		;;
	    ubuntu/*)
		opts="$opts --mirror http://wwwftp.ciril.fr/pub/linux/ubuntu/archives/"
		opts="$opts --debootstrapopts --keyring --debootstrapopts /usr/share/keyrings/ubuntu-archive-keyring.gpg"
		;;
	esac
        local target=$distrib.$arch
	_vbe_title "cowbuilder-$distrib: $@"
        sudo env DEBIAN_BUILDARCH="$arch" cowbuilder "$@" \
	    --distribution ${distrib##*/}  \
            --basepath /var/cache/pbuilder/bases/$target.cow \
            --buildresult /var/cache/pbuilder/results/$target \
            ${=opts}
    }
    alias cowbuilder-sid='_vbe_cowbuilder debian/sid ""'
    alias cowbuilder-squeeze='_vbe_cowbuilder debian/squeeze ""'
    alias cowbuilder-lenny='_vbe_cowbuilder debian/lenny ""'
    alias cowbuilder-maverick-i386='_vbe_cowbuilder ubuntu/maverick i386'
    alias cowbuilder-oneiric-i386='_vbe_cowbuilder ubuntu/oneiric i386'
    alias cowbuilder-precise-i386='_vbe_cowbuilder ubuntu/precise i386'
}
