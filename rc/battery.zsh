# -*- sh -*-

_vbe_battery () {
    [[ -d /sys/class/power_supply/BAT0 ]] || return
    local cache=$ZSH/run/u/$HOST-$UID/acpi
    if [[ -f $cache ]] && \
	(( $EPOCHSECONDS - $(zstat +mtime $cache) < 240 )); then
	print -n $(<$cache)
	return
    fi

    local percent
    local state
    percent=$(</sys/class/power_supply/BAT0/capacity)
    state=${$(</sys/class/power_supply/BAT0/status):l}
    [[ $state == (dis|)charging ]] || {
	: > $cache
	return
    }

    local -a gauge
    local size=4
    local full
    local g
    local i j
    if _vbe_can_do_unicode; then
        gauge=(▲ ▼ △ ▽)
    else
        gauge=(+ - . .)
    fi
    full=$(( (${percent}*${size}+49)/100 ))
    if (( $percent < 10 )); then
	g=red
    elif (( $percent < 30 )); then
	g=yellow
    else
	g=green
    fi
    i=1
    [[ $state == "discharging" ]] && i=2
    local gg
    (( $full >= 1 )) && for j in {1..$full}; do gg=$gg$gauge[$i]; done
    i=$(( $i + 2 ))
    (( $full < $size )) && \
	for j in {$(( $full + 1 ))..$size}; do gg=$gg$gauge[$i]; done
    print -n $g $gg > $cache
    print $g $gg
}

[[ $USERNAME != "root" ]] && [[ -d /sys/class/power_supply/BAT0 ]] && {

    _vbe_add_prompt_battery () {
        (($_vbe_cmd_elapsed < 0)) && return
        local v="$(_vbe_battery)"
        local color=${v% *}
        local gauge="${v#* }"

        [[ -n $gauge ]] && \
            _vbe_prompt_segment $color black %B$gauge
    }

}
