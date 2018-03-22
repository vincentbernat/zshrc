# -*- sh -*-

# We provide an enhanced cowbuilder command.  It will mimic a bit what
# git-pbuilder is doing. Here are the features:
#
#   1. It will use /var/cache/pbuilder/base-$DIST-$ARCH.cow.
#   2. It will take as first argument something like $DIST/$ARCH.
#   3. If $DIST contains an hyphen, some special rules may be
#      applied. Currently, if it ends with -backports, the backports
#      mirror will be added.

(( $+commands[cowbuilder] )) && {
    cowbuilder() {

        # Usage
        (( $# > 0 )) || {
            print "$0 distrib[/arch] ..." >&2
            return 1
        }

        # Architecture
        local arch
        case $1 in
            */*)
                arch=${1#*/}
                distrib=${1%/*}
                ;;
            *)
                distrib=$1
                ;;
        esac
        shift
        local -a opts
        local -a prefix

        case $arch in
            i386|)
                opts=(--debootstrap debootstrap)
                ;;
            *)
                # Needs qemu-user-static
                opts=(--debootstrap qemu-debootstrap)
                ;;
        esac

        # Distribution
        case ${distrib%%-*} in
            lenny|squeeze)
                opts=($opts --mirror http://snapshot.debian.org/archive/debian-archive/20160313T130328Z/debian)
                opts=($opts
                    --debootstrapopts --keyring
                    --debootstrapopts /usr/share/keyrings/debian-archive-keyring.gpg)
                ;;
            wheezy|jessie|stretch|sid)
                opts=($opts --mirror http://deb.debian.org/debian)
                opts=($opts
                    --debootstrapopts --keyring
                    --debootstrapopts /usr/share/keyrings/debian-archive-keyring.gpg)
                ;;
            precise|quantal|raring|saucy|trusty|utopic|vivid|wily|xenial|yakkety|zesty|artful)
                local mirror=http://archive.ubuntu.com/ubuntu
                opts=($opts --mirror $mirror)
                opts=($opts
                    --debootstrapopts --keyring
                    --debootstrapopts /usr/share/keyrings/ubuntu-archive-keyring.gpg)
                opts=($opts --components 'main universe')
                opts=($opts --othermirror "deb ${mirror} ${distrib%%-*}-updates main universe")
                opts=($opts --extrapackages pkg-create-dbgsym)
                ;;
        esac

        # Flavor
        case ${distrib} in
            squeeze-backports)
                opts=($opts --othermirror "deb http://backports.debian.org/debian-backports squeeze-backports main")
                ;;
            squeeze-lts)
                opts=($options --othermirror "deb http://snapshot.debian.org/archive/debian-archive/20160313T130328Z/debian squeeze-lts main")
                ;;
            *-backports-sloppy)
                opts=($opts --othermirror "deb http://httpredir.debian.org/debian ${distrib%-sloppy} main|deb http://httpredir.debian.org/debian ${distrib} main")
                ;;
            *-backports)
                opts=($opts --othermirror "deb http://httpredir.debian.org/debian ${distrib} main")
                ;;
        esac

        local target
        if [[ -n $arch ]]; then
            target=$distrib-$arch
            opts=($opts --debootstrapopts --arch --debootstrapopts $arch)
        else
            target=$distrib
        fi

        _vbe_title "cowbuilder $target: $*"
        sudo env DEBIAN_BUILDARCH="$arch" $prefix cowbuilder $1 \
            --distribution ${distrib%%-*}  \
            --basepath /var/cache/pbuilder/base-${target}.cow \
            --buildresult $PWD \
            $opts $*[2,$#]
    }
}
