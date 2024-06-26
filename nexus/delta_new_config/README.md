# Nexus Delta

## EFS manual steps

```bash
sudo mkdir efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-0869c9e1749a3d5d8.efs.us-east-1.amazonaws.com:/ efs
cd efs/
sudo mkdir opt
sudo mkdir appconf
sudo mkdir search-config
sudo mkdir disk-storage
cd appconf
vim delta.conf
```

And set the `delta.conf` to be the appropriate delta config.