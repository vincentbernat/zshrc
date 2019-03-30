# -*- sh -*-

# We provide an enhanced cowbuilder command.  It will mimic a bit what
# git-pbuilder is doing. Here are the features:
#
#   1. It will use /var/cache/pbuilder/base-$DIST-$ARCH.cow.
#   2. It will take as first argument something like $DIST/$ARCH.
#   3. If $DIST contains an hyphen, some special rules may be
#      applied. Currently, if it ends with -backports, the backports
#      mirror will be added.
#
# Note: have a look at cowbuilder-dist in ubuntu-dev-tools which is similar.

(( $+commands[cowbuilder] )) && {
    cowbuilder() {

        # Usage
        (( $# > 0 )) || {
            print "$0 distrib[/arch] ..." >&2
            return 1
        }

        # Architecture
        local distrib
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

        if [[ -z $arch ]] || [[ $arch == $(dpkg-architecture -q DEB_BUILD_ARCH) ]]; then
                opts=(--debootstrap debootstrap)
        else
            case $arch,$(dpkg-architecture -q DEB_BUILD_ARCH) in
                amd64,i386)
                    opts=(--debootstrap debootstrap)
                    ;;
                *)
                    # Needs qemu-user-static
                    opts=(--debootstrap qemu-debootstrap)
                    ;;
            esac
        fi

        # Distribution
        local -a debians ubuntus
        ubuntus=(/usr/share/debootstrap/scripts/*(e,'[ ${REPLY}(:A) = /usr/share/debootstrap/scripts/gutsy ]',))
        ubuntus=(${ubuntus##*/})
        debians=(/usr/share/debootstrap/scripts/*(e,'[ ${REPLY}(:A) = /usr/share/debootstrap/scripts/sid ]',))
        debians=(${debians##*/})
        if [[ ${debians[(r)${distrib%%-*}]} == ${distrib%%-*} ]]; then
                opts=($opts --mirror http://deb.debian.org/debian)
                opts=($opts
                    --debootstrapopts --keyring
                    --debootstrapopts /usr/share/keyrings/debian-archive-keyring.gpg)
        elif [[ ${ubuntus[(r)${distrib%%-*}]} == ${distrib%%-*} ]]; then
                local mirror=http://archive.ubuntu.com/ubuntu
                opts=($opts --mirror $mirror)
                opts=($opts
                    --debootstrapopts --keyring
                    --debootstrapopts /usr/share/keyrings/ubuntu-archive-keyring.gpg)
                opts=($opts --components 'main universe')
                opts=($opts --othermirror "deb ${mirror} ${distrib%%-*}-updates main universe")
                case ${distrib%%-*} in
                    precise|trusty|xenial)
                        opts=($opts --extrapackages pkg-create-dbgsym)
                        ;;
                esac
        fi

        # Flavor
        case ${distrib} in
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
