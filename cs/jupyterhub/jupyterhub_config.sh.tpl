#!/bin/bash

EFS_MOUNT_OPS="nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport"

sudo apt update
sudo apt install nfs-common nginx nodejs jq npm -y
sudo mount -t nfs4 -o $${EFS_MOUNT_OPS} ${HOMEDIRS_EFS}:/ ${HOMEDIRS_PATH}

# clean up all EFS jupyter users homedirs
sudo rm -rf ${HOMEDIRS_PATH}/jupyter-*

sudo echo -n "${HOMEDIRS_EFS}:/ ${HOMEDIRS_PATH} nfs4 $${EFS_MOUNT_OPS} 0 0" >> /etc/fstab
sudo mount -a

# to be able to ssh as ubuntu user
sudo mkdir -p /home/ubuntu/.ssh/
sudo chown -R ubuntu:ubuntu /home/ubuntu/
sudo echo "${CS_SSH_KEY}" > /home/ubuntu/.ssh/authorized_keys
sudo chmod 700 /home/ubuntu/.ssh
sudo chmod 600 /home/ubuntu/.ssh/authorized_keys

sudo systemctl enable nginx
sudo systemctl stop nginx

curl -L https://tljh.jupyter.org/bootstrap.py \
  | sudo python3 - \
    --admin ${ADMIN_USER}:${ADMIN_PASS} \
    --user-requirements-txt-url https://s3.amazonaws.com/${PRIMARY_DOMAIN}/static/jupyterhub_requirements.txt \
    --version 2.0.0 \
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

mkdir -p ${SHARED_DIR_PATH}
# RO for jupyterhub users, full access for root
sudo chown -R root:jupyterhub-users ${SHARED_DIR_PATH}
sudo chmod -R 2750 ${SHARED_DIR_PATH}

# from: https://tljh.jupyter.org/en/latest/howto/content/share-data.html
sudo ln -s ${SHARED_DIR_PATH} /etc/skel/shared_data

# users to jupyterhub-admins: ${JUPYTERHUB_ADMINS}
JUPYTERHUB_ADMINS_SET=""
for USERNAME in $(echo "${JUPYTERHUB_ADMINS}" | xargs)
do
  sudo tljh-config add-item users.admin jupyter-$${USERNAME}
  JUPYTERHUB_ADMINS_SET="'$${USERNAME}' $${JUPYTERHUB_ADMINS_SET}"
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
c.GenericOAuthenticator.username_claim = "preferred_username"
c.GenericOAuthenticator.scope = ["openid"]

# jupyterhub-admins users need to be allowed at the Authenticator level
c.GenericOAuthenticator.admin_users = { $${JUPYTERHUB_ADMINS_SET} }

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

source /opt/tljh/user/bin/activate
pip install obi-auth
conda deactivate

# Restart JupyterHub service to apply changes
sudo tljh-config reload proxy
sudo tljh-config reload

# Restart nginx reverse proxy
sudo systemctl restart nginx
