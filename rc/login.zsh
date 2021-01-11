# -*- sh -*-
# To be execute at login only.

[[ -o login ]] && {
    # Cumulus puts some important information in these files.
    for f in /etc/profile.d/*motd.sh(N); do
        bash $f
    done
}
