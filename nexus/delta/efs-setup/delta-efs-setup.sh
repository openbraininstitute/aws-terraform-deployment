# Modify this variable to be the folder where
# the EFS used by Delta is mounted
DELTA_FOLDER=/nexus-delta-efs
cd $DELTA_FOLDER

# Put the contents of delta.conf inside this file
# and modify the link inside it as appropriate
vim $DELTA_FOLDER/opt/appconf/delta.conf

# Populate the search-config folder with the contents of
# https://github.com/BlueBrain/nexus/tree/master/tests/docker/config
cd $DELTA_FOLDER/opt/search-config
vim construct-query.sparql
vim fields.json
# etc.