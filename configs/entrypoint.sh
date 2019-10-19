#!/usr/bin/env bash

# ensure USER and USERID is not root.
if [ "$USER" == "root" ]; then
    USER="user"
fi

if [ "$USERID" == "0" ]; then
    USERID=1000
fi

if [ -z "$TAG" ]; then
    export TAG="latest"
fi

# enter py env.
source activate py3

# setup $USER now.
mv -f /etc/cont-init.d/userconf /tmp/userconf.sh
chmod +x /tmp/userconf.sh
source /tmp/userconf.sh

site_dir="/home/${USER}/__ShinyStudio__"
if [ -d "$site_dir" ]; then
    
    # if this is a superadmin, set correct site_dir path.
    if [ -d "$site_dir/users" ]; then
        if [ -z "${SITE_NAME}" ]; then
            SITE_NAME="shinystudio"
        fi
        site_dir="${site_dir}/sites/${SITE_NAME}"
        mkdir -p "$site_dir"
    fi
    
    # create site folders, if necessary, and ensure $USERID owns them.
    for d in _apps _docs
    do
        dir="$site_dir/$d"
        if [ ! -d "$dir" ] || [ ! -z "$(find ""$dir"" -maxdepth 0 -empty)" ]; then
            [ -d "$dir" ] || mkdir -p "$dir"
            cp -R "/srv/shiny-server/$d/." "$dir"
            chown -R $USERID:$USERID "$dir"
        fi
    done
fi

# Do this to ensure 'SHINYPROXY_USERNAME' and 'SHINYPROXY_GROUPS'
# are available in the rstudio user's environment.
env | grep "SHINYPROXY" > "/home/${USER}/.Renviron"

# setup .gitconfig for this user.
echo "[user]
    name = ${USER}
    email = none@none.com" > "/home/${USER}/.gitconfig"

# make shiny-examples available; read-only.
ln -sf /srv/shiny-server "/home/${USER}/shiny-examples"

# parse arg $1 to define service to run
svc="$1"

if [ -z "$svc" ]; then
    svc='shinyproxy'
fi

find /etc/services.d/* -type d -not -name "$svc" | xargs rm -rf

/init
