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
    local cache=$ZSH/run/acpi-$HOST-$UID
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
    gauge=('#' '#' '-' '-')
    is-at-least 4.3.4 && [[ -o multibyte ]] && gauge=(▲ ▼ △ ▽)
    full=$(( (${percent}*${size}+49)/100 ))
    if (( $percent < 10 )); then
	g=$PR_RED
    elif (( $percent < 30 )); then
	g=$PR_YELLOW
    else
	g=$PR_GREEN
    fi
    i=1
    [[ $state == "discharging" ]] && i=2
    (( $full >= 1 )) && for j in {1..$full}; do g=$g$gauge[$i]; done
    i=$(( $i + 2 ))
    (( $full < $size )) && \
	for j in {$(( $full + 1 ))..$size}; do g=$g$gauge[$i]; done
    print -n $g
    print -n $g > $cache
}

_vbe_add_prompt_battery () {
    print -n '${PR_GREY}|$(_vbe_battery)${PR_GREY}|'
    print -n '$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT'
}
