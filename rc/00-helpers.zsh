# -*- sh -*-

# Get the first non optional argument
_vbe_first_non_optional_arg() {
    local args
    args=( "$@" )
    args=( ${(R)args:#-*} )
    print -- $args[1]
}
