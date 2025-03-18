#!/bin/bash

EFS_MOUNT_OPS="nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport"

sudo apt update
sudo apt install nfs-common nginx nodejs jq npm -y
sudo mount -t nfs4 -o $${EFS_MOUNT_OPS} ${HOMEDIRS_EFS}:/ ${HOMEDIRS_PATH}

# clean up all EFS jupyter users homedirs
sudo rm -rf ${HOMEDIRS_PATH}/jupyter-*

sudo echo -n "${HOMEDIRS_EFS}:/ ${HOMEDIRS_PATH} nfs4 $${EFS_MOUNT_OPS} 0 0" >> /etc/fstab
sudo mount -a

sudo systemctl enable nginx
sudo systemctl stop nginx

curl -L https://tljh.jupyter.org/bootstrap.py \
  | sudo python3 - \
    --admin ${ADMIN_USER}:${ADMIN_PASS} \
    --version 0.2.0 \
    --user-requirements-txt-url https://gist.githubusercontent.com/danifr/6d0c4ff74a51ebb076179447855b9849/raw/1b183e30bc8513e9310bd49d0ed584dceb16e7b2/requirements.txt \
    --show-progress-page \

sudo tljh-config set base_url ${BASE_PATH}
sudo tljh-config set http.port ${JUPYTERHUB_PORT}
# limit session to 30 mins
sudo tljh-config set services.cull.max_age 1800

# set default interface to jupyterlab and disable autosave feature
sudo tljh-config set user_environment.default_app jupyterlab
for DIR in $(find /opt/tljh/ -name docmanager-extension -type d); do
  cat <<< $(jq '.properties.autosave.default = false' $DIR/plugin.json) > $DIR/plugin.json
done

# Setup Keycloak as a GenericOAuthenticator
cat <<EOF > /opt/tljh/config/jupyterhub_config.d/keycloak.py
c.JupyterHub.authenticator_class = "generic-oauth"

c.GenericOAuthenticator.client_id = "${KC_CLIENT_ID}"
c.GenericOAuthenticator.client_secret = "${KC_CLIENT_SECRET}"
c.GenericOAuthenticator.oauth_callback_url = "https://${PRIMARY_DOMAIN}${BASE_PATH}/hub/oauth_callback"

c.GenericOAuthenticator.authorize_url = "https://${PRIMARY_DOMAIN}/auth/realms/${KC_REALM}/protocol/openid-connect/auth"
c.GenericOAuthenticator.token_url = "https://${PRIMARY_DOMAIN}/auth/realms/${KC_REALM}/protocol/openid-connect/token"
c.GenericOAuthenticator.userdata_url = "https://${PRIMARY_DOMAIN}/auth/realms/${KC_REALM}/protocol/openid-connect/userinfo"

c.GenericOAuthenticator.login_service = "Keycloak login"
c.GenericOAuthenticator.username_key =  "preferred_username"
c.GenericOAuthenticator.scope = ["openid"]

c.GenericOAuthenticator.allow_all = True
c.GenericOAuthenticator.auto_login = True
c.GenericOAuthenticator.auto_login_oauth2_authorize = True
c.GenericOAuthenticator.validate_server_cert = False
EOF

# Setup Nginx as reverse proxy for JupyterHub
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-available/default
# adapted from https://jupyterhub.readthedocs.io/en/stable/howto/configuration/config-proxy.html#nginx
cat <<EOF > /etc/nginx/sites-enabled/jupyterhub.conf
# Top-level HTTP config for WebSocket headers
# If Upgrade is defined, Connection = upgrade
# If Upgrade is empty, Connection = close
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''      close;
}

server {
    listen 80;
    server_name ${PRIMARY_DOMAIN};

    # Prevent double slashes and recursive redirects
    rewrite ^/(.*)//+(.*)$ /\$1/\$2 permanent;

    # Forward all traffic to port JUPYTERHUB_PORT
    location ${BASE_PATH} {
        proxy_pass http://localhost:${JUPYTERHUB_PORT}${BASE_PATH};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # websocket headers
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header X-Scheme \$scheme;

        proxy_buffering off;
    }
}
EOF

#
# Julia installation
JULIA_VERSION="1.6.6"
JULIA_VER=$(cut -d '.' -f -2 <<< "$JULIA_VERSION")
BASE_URL="https://julialang-s3.julialang.org/bin/linux/x64"
URL="$BASE_URL/$JULIA_VER/julia-$JULIA_VERSION-linux-x86_64.tar.gz"

wget -nv $URL -O /tmp/julia.tar.gz
tar -x -f /tmp/julia.tar.gz -C /usr/local --strip-components 1
rm /tmp/julia.tar.gz
ln -s /usr/local/bin/julia /opt/tljh/user/bin/julia

export JULIA_DEPOT_PATH=/opt/tljh/user/share/julia/
export JUPYTER_DATA_DIR=/opt/tljh/user/share/jupyter/

declare -A JULIA_PACKAGES=(
  ["JSON"]="0.21.4"
  ["Symbolics"]="4.3.0"
  ["DifferentialEquations"]="7.2.0"
  ["ModelingToolkit"]="8.11.0"
  ["Plots"]="1.31.1"
  ["Interact"]="0.10.5"
  ["WebIO"]="0.8.21"
  ["IJulia"]="1.26.0"
  ["PyCall"]="1.96.4"
  ["BenchmarkTools"]="1.5.0"
)

# Install packages
for PKG in "$${!JULIA_PACKAGES[@]}"
do
  PKG_VERSION="$${JULIA_PACKAGES[$PKG]}"
  echo "Installing Julia package $PKG $PKG_VERSION..."
  julia -e "using Pkg; Pkg.add(name=\"$${PKG}\", version=\"$${PKG_VERSION}\"); precompile;"
done

julia -e 'using Pkg; Pkg.build("Interact")'

# Install kernel
JULIA_NUM_THREADS=8
echo "Installing IJulia kernel..."
julia -e 'using IJulia; IJulia.installkernel("julia", env=Dict(
      "JULIA_NUM_THREADS"=>"'"$JULIA_NUM_THREADS"'",
      "JULIA_DEPOT_PATH"=>"'"$JULIA_DEPOT_PATH"'",
      "JUPYTER_DATA_DIR"=>"'"$JUPYTER_DATA_DIR"'"
))'

# downgrade bcrypt to avoid AttributeError: module 'bcrypt' has no attribute '__about__' error
source /opt/tljh/hub/bin/activate
pip install --upgrade bcrypt==4.0.1
deactivate

source /opt/tljh/user/bin/activate
pip install webio_jupyter_extension webio_jupyterlab_provider
pip install --upgrade jupyterlab-pygments==0.2.0
conda deactivate

# Give jupyterhub-users groups access to $JULIA_DEPOT_PATH
chgrp -R jupyterhub-users $${JULIA_DEPOT_PATH}
chmod 664 $${JULIA_DEPOT_PATH}/logs/repl_history.jl
chmod 664 $${JULIA_DEPOT_PATH}/logs/manifest_usage.toml

# Restart JupyterHub service to apply changes
sudo tljh-config reload proxy
sudo tljh-config reload

# Restart nginx reverse proxy
sudo systemctl restart nginx
