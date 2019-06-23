#!/usr/bin/env bash

# enter pyenv
source "${VIRTUAL_ENV}/bin/activate"

# setup $USER now
mv -f /etc/cont-init.d/userconf /tmp/userconf.sh
chmod +x /tmp/userconf.sh
source /tmp/userconf.sh

site_dir="/home/${USER}/__ShinyStudio__"
if [ -d "$site_dir" ]; then
    
    # if this is a superadmin, set correct site_dir path.
    if [ -d "$site_dir/users" ]; then
        site_dir="${site_dir}/sites/${SITEID}"
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

    # first launch setup.
    if [ -d "/home/${USER}/__Personal__/.vscode" ] && [ ! -f "/home/${USER}/__Personal__/.vscode/User/settings.json" ]; then
        su - $USER -c 'cd ~ && export SHELL=/bin/bash && /setup_vscode.sh'
    fi
fi

# Do this to ensure 'SHINYPROXY_USERNAME' and 'SHINYPROXY_GROUPS'
# are available in the rstudio user's environment.
env | grep "SHINYPROXY" > "/home/${USER}/.Renviron"

# set non-standard port for Jupyter notebook, for use in VS code.
mkdir -p "/home/${USER}/.jupyter"

echo "c.NotebookApp.ip = '127.0.0.1'
c.NotebookApp.port = 12345
c.NotebookApp.port_retries = 50
c.NotebookApp.token = ''
c.NotebookApp.open_browser = False
c.NotebookApp.disable_check_xsrf = True" > "/home/${USER}/.jupyter/jupyter_notebook_config.py"


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
