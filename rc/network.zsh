# -*- sh -*-

# Some network related functions

__add_to_bridge() {
    # Optionally, add it to given bridge
    [[ -z $2 ]] || {
	[[ -f /sys/class/net/$2/brforward ]] || {
	    sudo brctl addbr $2
	    sudo brctl stp $2 off
	    sudo ip link set $2 up
	}
	[[ -f /sys/class/net/$2/brif/$1 ]] || {
	    # We need to check if it is in another bridge
	    bridge=$(echo /sys/class/net/*/brif/$1 2> /dev/null | \
		sed 's+/sys/class/net/\([^/]*\)/.*+\1+') 2> /dev/null
	    [[ -n $bridge ]] && \
		sudo brctl delif $bridge $1
	    sudo brctl addif $2 $1
        }
    }
}

# Create a tun interface
# First arg: name of the interface
# Second arg: name of the bridge (optional)
tun() {
    sudo tunctl -b -u $USERNAME -t $1 > /dev/null
    sudo ip link set up dev $1
    __add_to_bridge $1 $2
}

# Same as tun but for veth (only the second end is put into the bridge)
# First arg: name of the first end
# Second arg: name of the second enf
# Third arg: name of the bridge (optional)
veth() {
    sudo ip link add name $1 type veth peer name $2 2> /dev/null || true
    sudo ip link set up dev $1
    sudo ip link set up dev $2
    __add_to_bridge $2 $3
}
