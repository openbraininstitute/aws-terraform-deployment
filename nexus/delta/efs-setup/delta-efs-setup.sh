DELTA_FOLDER=/nexus-delta-efs
cd $DELTA_FOLDER

# Create the /opt folder inside EFS
sudo mkdir opt
sudo chmod 777 opt

# Create the appconf folder inside /opt
cd $DELTA_FOLDER/opt
sudo mkdir appconf
sudo chmod 777 appconf

# Put the contents of delta.conf inside this file
# and modify the link inside it as appropriate
vim $DELTA_FOLDER/opt/appconf/delta.conf

# Create the disk-storage folder inside /opt
cd $DELTA_FOLDER/opt
sudo mkdir disk-storage
sudo chmod 777 disk-storage

# Create the search-config folder inside /opt
cd $DELTA_FOLDER/opt
sudo mkdir search-config
sudo chmod 777 search-config

# Populate the search-config folder with the contents of
# https://github.com/BlueBrain/nexus/tree/master/tests/docker/config
cd $DELTA_FOLDER/opt/search-config
vim construct-query.sparql
vim fields.json
# etc.