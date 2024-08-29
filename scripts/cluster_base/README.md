# DZ Cluster Base

This handles all the setup necessary to get a working dz cluster. We need a cri-o cluster, but sysbox uses a slightly modified version of cri-o and some custom setup for id-mappings, so we first create a docker minikube cluster, install sysbox into it and then recreate the minikube cluster using the cri-o runtime that sysbox installed.

```
# start the lima vm
make start

# export an image
make image
```