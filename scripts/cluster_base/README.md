# DZ Cluster Base

This handles all the setup necessary to get a working dz cluster. We need a cri-o cluster, but sysbox uses a slightly modified version of cri-o and some custom setup for id-mappings, so we first create a docker minikube cluster, install sysbox into it and then recreate the minikube cluster using the cri-o runtime that sysbox installed.

```
# start the lima vm
make start

# shell into it
make shell

# delete the existing containerd minikube cluster and create a new cri-o one
minikube delete
minikube start --driver=none --container-runtime=cri-o --kubernetes-version=v1.29.0 --cni=bridge

# wait for pods to be running
kubectl get pods -Aw

# reapply sysbox
kubectl label nodes --all node-role.kubernetes.io/devpod-node=1
kubectl label nodes --all sysbox-install=yes
kubectl apply -f https://raw.githubusercontent.com/nestybox/sysbox/master/sysbox-k8s-manifests/sysbox-install.yaml

# apply generic device plugin and fake gp2 storage class that are in the home dir
kubectl apply -f .

# wait for pods to be running
kubectl get pods -Aw
```