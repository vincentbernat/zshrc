# -*- sh -*-

ssh() {
    # LANG and LC_MESSAGES are ones of the variables that is usually
    # allowed to be transmitted to the remote session. We reset them
    # to C to avoid any problem with hosts not having your locally
    # installed locales. See this post for more details on this:
    #   http://vincent.bernat.im/en/blog/2011-zsh-zshrc.html
    #
    # When the same ZSH configuration is used on the remote host, the
    # locale is reset with the help of `$ZSH/rc/01-locale.zsh`.
    LANG=C LC_MESSAGES=C command ssh "$@"
}

# The following command implements a reverse SSH connection. This is
# to connect to hosts behind a firewall, which can connect to your
# machine but you cannot connect directly. The idea is that they issue
# a TCP connection that you will use as a tunnel to access their SSH
# port.
#
# I am using this to connect to VM using user-mode network (QEMU, KVM,
# UML, ...).
rssh() {
    # We should probe for a free port, but is it easy?
    local port
    port=$((21422 + $RANDOM % 1000))

    print "On remote host, use \`socat TCP:10.0.2.2:$port TCP:127.0.0.1:22\` to allow SSH access... "
    ssh -oProxyCommand="socat TCP-LISTEN:$port,bind=127.0.0.1,reuseaddr STDIO" \
        "$@"
}
