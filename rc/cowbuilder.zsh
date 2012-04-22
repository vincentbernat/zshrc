# -*- sh -*-

(( $+commands[cowbuilder] )) && {
    cowbuilder() {
	# First argument is something like this:
	#   debian/squeeze
	#   debian/squeeze/i386
	#   ubuntu/oneiric/amd64
	#   ubuntu/oneiric.custom
	# Remaining arguments are those for cowbuilder

	# Architecture
	local arch
	case $1 in
	    */*/*)
		arch=${1##*/}
		distrib=${1%/*}
		;;
	    *)
		arch=$(dpkg --print-architecture)
		distrib=$1
		;;
	esac
	shift
        local -a opts
	opts=(--debootstrap debootstrap --debootstrapopts --arch --debootstrapopts $arch)

	# Distribution
	case $distrib in
	    debian/*)
		opts=($opts --mirror http://ftp.fr.debian.org/debian)
		opts=($opts --debootstrapopts --keyring --debootstrapopts /usr/share/keyrings/debian-archive-keyring.gpg)
		;;
	    ubuntu/*)
		opts=($opts --mirror http://wwwftp.ciril.fr/pub/linux/ubuntu/archives/)
		opts=($opts --debootstrapopts --keyring --debootstrapopts /usr/share/keyrings/ubuntu-archive-keyring.gpg)
		opts=($opts --components 'main universe')
		;;
	esac
	distrib=${distrib##*/}

        local target=$distrib.$arch
	distrib=${distrib%.*}
	_vbe_title "cowbuilder $target: $@"
        sudo env DEBIAN_BUILDARCH="$arch" cowbuilder "$@" \
	    --distribution ${distrib}  \
            --basepath /var/cache/pbuilder/bases/$target.cow \
            --buildresult /var/cache/pbuilder/results/$target \
	    $opts
    }
}
