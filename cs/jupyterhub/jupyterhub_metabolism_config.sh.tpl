#!/bin/bash
exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

EFS_MOUNT_OPS="nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport"

sudo apt update
sudo apt install nfs-common nginx nodejs jq npm git -y
sudo mount -t nfs4 -o $${EFS_MOUNT_OPS} ${HOMEDIRS_EFS}:/ ${HOMEDIRS_PATH} \
  || { echo "FATAL: EFS mount failed"; exit 1; }

# clean up all EFS jupyter users homedirs
sudo rm -rf ${HOMEDIRS_PATH}/jupyter-*

grep -qF "${HOMEDIRS_EFS}" /etc/fstab \
  || echo -n "${HOMEDIRS_EFS}:/ ${HOMEDIRS_PATH} nfs4 $${EFS_MOUNT_OPS} 0 0" | sudo tee -a /etc/fstab
sudo mount -a || true

# to be able to ssh as ubuntu user
sudo mkdir -p /home/ubuntu/.ssh/
sudo chown -R ubuntu:ubuntu /home/ubuntu/
echo "${CS_SSH_KEY}" | sudo tee /home/ubuntu/.ssh/authorized_keys
sudo chmod 700 /home/ubuntu/.ssh
sudo chmod 600 /home/ubuntu/.ssh/authorized_keys

sudo systemctl enable nginx
sudo systemctl stop nginx

# Bootstrap TLJH - will fail on bcrypt/passlib incompatibility but that's expected
curl -L https://tljh.jupyter.org/bootstrap.py \
  | sudo python3 - \
    --admin ${ADMIN_USER}:${ADMIN_PASS} \
    --version 0.2.0 \
    --user-requirements-txt-url https://gist.githubusercontent.com/danifr/6d0c4ff74a51ebb076179447855b9849/raw/1b183e30bc8513e9310bd49d0ed584dceb16e7b2/requirements.txt \
  || true

# Pin bcrypt in the hub venv to fix passlib AttributeError, then re-run the installer
/opt/tljh/hub/bin/pip install bcrypt==4.0.1
sudo /opt/tljh/hub/bin/python3 -m tljh.installer \
  --admin ${ADMIN_USER}:${ADMIN_PASS} \
  --user-requirements-txt-url https://gist.githubusercontent.com/danifr/6d0c4ff74a51ebb076179447855b9849/raw/1b183e30bc8513e9310bd49d0ed584dceb16e7b2/requirements.txt \
  || { echo "FATAL: TLJH installer failed"; exit 1; }

sudo tljh-config set base_url ${BASE_PATH}
sudo tljh-config set http.port ${JUPYTERHUB_PORT}
# limit session to 30 mins
sudo tljh-config set services.cull.max_age 1800

# set default interface to jupyterlab, open default notebook, and disable autosave feature
sudo tljh-config set user_environment.default_app jupyterlab
# default_url is not a tljh-config key, set it directly in jupyterhub config
echo 'c.Spawner.default_url = "/lab/tree/notebooks/analysis_notebook.ipynb"' \
  | sudo tee /opt/tljh/config/jupyterhub_config.d/default_url.py
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

    # avoid 413 errors when dealing with large notebook files
    client_max_body_size 50M;

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
ln -sf /usr/local/bin/julia /opt/tljh/user/bin/julia

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

source /opt/tljh/user/bin/activate
pip install webio_jupyter_extension webio_jupyterlab_provider
pip install --upgrade jupyterlab-pygments==0.2.0
deactivate

# Give jupyterhub-users groups access to $JULIA_DEPOT_PATH
chgrp -R jupyterhub-users $${JULIA_DEPOT_PATH}
touch $${JULIA_DEPOT_PATH}/logs/repl_history.jl $${JULIA_DEPOT_PATH}/logs/manifest_usage.toml
chmod 664 $${JULIA_DEPOT_PATH}/logs/repl_history.jl
chmod 664 $${JULIA_DEPOT_PATH}/logs/manifest_usage.toml

# Clone Metabolism notebooks into /etc/skel so every new user gets a personal copy on first login
git clone --filter=blob:none --no-checkout --depth=1 --sparse \
  https://github.com/openbraininstitute/obi_platform_analysis_notebooks.git /tmp/notebooks_clone
git -C /tmp/notebooks_clone sparse-checkout set Metabolism
git -C /tmp/notebooks_clone checkout
sudo mkdir -p /etc/skel/notebooks
sudo cp -r /tmp/notebooks_clone/Metabolism/. /etc/skel/notebooks/
rm -rf /tmp/notebooks_clone

# Reload JupyterHub config - stop traefik first to free port 80 for nginx
sudo systemctl stop traefik || true
sudo tljh-config reload proxy
sudo tljh-config reload

# Restart nginx reverse proxy
sudo systemctl restart nginx

