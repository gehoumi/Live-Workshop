#!/bin/bash

# installs standard single-cluster Istio on GKE + the Istio Stackdriver adapter

# Download Istio
WORKDIR="`pwd`"
ISTIO_VERSION="${ISTIO_VERSION:-1.5.2}"
echo "Downloading Istio ${ISTIO_VERSION}..."
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -

# Prepare for install
kubectl create namespace istio-system

cd ./istio-${ISTIO_VERSION}/
kubectl create secret generic cacerts -n istio-system \
    --from-file=samples/certs/ca-cert.pem \
    --from-file=samples/certs/ca-key.pem \
    --from-file=samples/certs/root-cert.pem \
    --from-file=samples/certs/cert-chain.pem
cd ../

kubectl label namespace default istio-injection=enabled
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)


# install using operator config - https://istio.io/docs/setup/install/istioctl/#customizing-the-configuration
INSTALL_PROFILE=${INSTALL_YAML:-default.yaml}
./istio-${ISTIO_VERSION}/bin/istioctl manifest apply -f ${INSTALL_PROFILE}
