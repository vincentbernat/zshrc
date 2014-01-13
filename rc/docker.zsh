# -*- sh -*-

# Sandbox with docker. This is similar to stevedore:
#  https://github.com/jpetazzo/stevedore/blob/master/stevedore

(( $+commands[docker.io] )) && alias docker=docker.io
(( $+commands[docker.io] + $+commands[docker] )) && {

    docker-sandbox() {
        local -A options

        zparseopts -D -A options -base: -sandbox: -packages:

        options[--base]=${options[--base]:-vincentbernat/debian:wheezy}
        options[--sandbox]=${options[--sandbox]:-vincentbernat/sandbox}

        if [[ $1 == --* ]] || [[ -z $1 ]]; then
            cat <<EOF
docker-sandbox [ --base IMAGE ] [ --sandbox REPOSITORY ] TAG

Create or run a new sandbox container. The container will be
PREFIX:TAG. If it doesn't exist, it will be created. Otherwise, it
will be run.
EOF
            return 2
        fi
        options[tag]=$1

        if [[ $(docker images | \
            awk '($1 == "'${options[--sandbox]}'" && $2 == "'${options[tag]}'") {print}' | \
            wc -l) -gt 0 ]]; then
            # Image found, run it
            docker run -h sandbox-${options[tag]} -t -i -v $HOME:$HOME -w $PWD \
                ${options[--sandbox]}:${options[tag]}
        else
            cat <<EOF | docker build -t=${options[--sandbox]}:${options[tag]} -
FROM ${options[--base]}

RUN apt-get -qy install sudo ${options[--packages]}
RUN echo $(getent passwd $(id -u)) >> /etc/passwd
RUN echo $(getent group $(id -g)) >> /etc/group
RUN echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER
RUN chmod 0440 /etc/sudoers.d/$USER

ENV HOME $HOME
USER $USER
ENTRYPOINT ["$SHELL", "-i", "-l"]
EOF
        fi
    }

}
