#!/bin/bash

sudo apt update
sudo apt install nfs-common -y
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${HOMEDIRS_EFS}:/ ${HOMEDIRS_PATH}

curl -L https://tljh.jupyter.org/bootstrap.py \
  | sudo python3 - \
    --admin ${ADMIN_USER}:${ADMIN_PASS} \
    --show-progress-page \
    --plugin webio-jupyter-extension==0.1.0

sudo tljh-config set base_url ${BASE_PATH}

# limit session to 30 mins
sudo tljh-config set services.cull.max_age 1800

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
c.GenericOAuthenticator.username_claim =  "preferred_username"
c.GenericOAuthenticator.scope = ["openid"]

c.GenericOAuthenticator.allow_all = True
c.GenericOAuthenticator.auto_login = True
c.GenericOAuthenticator.auto_login_oauth2_authorize = True
c.GenericOAuthenticator.validate_server_cert = False
EOF

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
  ["IJulia"]="1.26.0"
  ["DifferentialEquations"]="7.2.0"
  ["JSON"]="0.21.4"
  ["ModelingToolkit"]="8.11.0"
  ["Plots"]="1.31.1"
  ["Symbolics"]="4.3.0"
  ["WebIO"]="0.8.21"
  ["Interact"]="0.10.5"
)

# Install packages
for PKG in "${!JULIA_PACKAGES[@]}"; do
  PKG_VERSION="${JULIA_PACKAGES[$PKG]}"
  echo "Installing Julia package $PKG $PKG_VERSION..."
  julia -e "using Pkg; Pkg.add(name=\"${PKG}\", version=\"${PKG_VERSION}\"); precompile;"
done

# Install kernel
JULIA_NUM_THREADS=8
echo "Installing IJulia kernel..."
julia -e 'using IJulia; IJulia.installkernel("julia", env=Dict(
      "JULIA_NUM_THREADS"=>"'"$JULIA_NUM_THREADS"'",
      "JULIA_DEPOT_PATH"=>"'"$JULIA_DEPOT_PATH"'",
      "JUPYTER_DATA_DIR"=>"'"$JUPYTER_DATA_DIR"'"
))'

# Give jupyterhub-users groups access to $JULIA_DEPOT_PATH
chgrp -R jupyterhub-users ${JULIA_DEPOT_PATH}
chmod 664 ${JULIA_DEPOT_PATH}/logs/repl_history.jl
chmod 664 ${JULIA_DEPOT_PATH}/logs/manifest_usage.toml

# Restart JupyterHub service to apply changes
sudo tljh-config reload proxy
sudo tljh-config reload
