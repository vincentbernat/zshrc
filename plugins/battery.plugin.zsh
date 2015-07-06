# -*- sh -*-

# acpi -b output
#
# Battery X: YYYYYY, ZZ%
# Battery X: YYYYYY, ZZ%, rate information unavailable
# Battery X: YYYYYY, ZZ%, charging at zero rate
# Battery X: YYYYYY, ZZ%, discharging at zero rate
# Battery X: YYYYYY, ZZ%, HH:MM:SS remaining
# Battery X: YYYYYY, ZZ%, HH:MM:SS until charged
#
# YYYYYY = charging
# YYYYYY = discharging

_vbe_battery () {
    (( $+commands[acpi] )) || return
    local cache=$ZSH/run/u/$HOST/$UID/acpi
    zmodload zsh/stat
    zmodload zsh/datetime
    if [[ -f $cache ]] && \
	(( $EPOCHSECONDS - $(stat +mtime $cache) < 240 )); then
	print -n $(<$cache)
	return
    fi

    local acpi
    local percent
    local state
    acpi=(${(f)$(acpi -b)})
    percent=${(L)${${acpi[1]}#*, }%\%, *}
    state=${(L)${${acpi[1]}#*: }%%, *}
    [[ $state == (dis|)charging ]] || {
	: > $cache
	return
    }

    local -a gauge
    local size=4
    local full
    local g
    local i j
    _vbe_can_do_unicode && gauge=(▲ ▼ △ ▽) || gauge=('#' '#' '-' '-')
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

_vbe_add_prompt_battery () {
    local v="$(_vbe_battery)"
    local color=${v% *}
    local gauge="${v#* }"
    
    _vbe_prompt_segment $color black %B$gauge
}
