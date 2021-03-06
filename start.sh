#!/bin/sh
#set -ex

# This project was tested using:
#   Minikube 0.25.2
#   Kubernetes 1.9.4
#   KubeCtl 1.10.0
#   Helm 2.8.2

# Start minikube and ensure security for our demonstration container registry is off
# You may want to adjust the cpu and memory resources to work with your target machine
##minikube start --kubernetes-version v1.9.0 --cpus 4 --memory 8000 --bootstrapper kubeadm --insecure-registry '192.168.99.0/24'
minikube start --kubernetes-version v1.9.4 --cpus 4 --memory 8000  --insecure-registry '192.168.99.0/24'

# See https://github.com/kubernetes/minikube/tree/master/deploy/addons
minikube addons enable registry
minikube addons enable heapster
minikube addons enable efk
minikube addons enable ingress

# May be a few moments before service is ready to respond to a patch request
# Expose the Registry externally as a NodePort (use 'minikube service list' to find the URL of services)
for i in {1..10}; do \
kubectl patch service registry --namespace=kube-system --type='json' -p='[{"op": "replace",  "path": "/spec/type", "value":"NodePort"}]' \
&& break || echo 'OK, retrying NodePort adjustment for registry...' && sleep 10; done

# After registry is added, map it to port 5000 so all images can be pulled from localhost:5000
kubectl apply -f configurations/registry-proxy.yaml

minikube status
echo "$(minikube version) is now ready"
echo "Be sure to now run this command: '. ./env.sh'"

# Troubleshooting:
# If Minikube does not start correctly, try wiping it clean with `minikube delete`, then
# remove `~/.minikube` directory then run this script again. If this does not help sometimes
# a cleaner slate such as removing `~/.minikube`, `~/.kube` and `~/.virtualbox` may help.
