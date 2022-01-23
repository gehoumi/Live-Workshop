# Kubernetes-101

Introduction to kubernetes and learning Labs to build, deploy and test `Docker-packaged` application, and to take your understanding of containers and microservices to the next level.

- Kubernetes_Architecture: https://collabnix.github.io/kubelabs/Kubernetes_Architecture.html

1. **Create a k8s cluster.**

```bash
terraform plan/apply

# 1-  Bootstrapping the Cluster with default node count =1
# 2 - Setting up Worker Node : Add another custom node pool node count =4
```

2. **Configure cluster access for kubectl**

Kubernetes uses a YAML file called kubeconfig to store cluster authentication information for kubectl. kubeconfig contains a list of contexts to which kubectl refers when running commands. By default, the file is saved at `$HOME/.kube/config`.

For GCP:
```
gcloud container clusters get-credentials main-cluster --zone us-central1 --project <project_name>
```

Verifying Kubernetes Cluster
Run the below command on master node
```
$ kubectl get nodes
```

- kubelabs - Kubernetes Hands-on Labs: https://collabnix.github.io/kubelabs
- Preparing 5-Node Kubernetes Cluster: https://collabnix.github.io/kubelabs/kube101.html

- Other Labs environment: https://www.katacoda.com/courses/kubernetes
- Other Labs environment: https://labs.play-with-k8s.com

- kubectl Cheat Sheet:
https://kubernetes.io/docs/reference/kubectl/cheatsheet/

3. **Clone this repository.**

```
git clone https://github.com/gehoumi/Live-Workshop.git
cd Live-Workshop/kubernetes-101/microservices-demo
```
This demo uses **Google Online Boutique** a cloud-native microservices demo application.
Online Boutique consists of a 10-tier microservices application. The application is a
web-based e-commerce app where users can browse items,
add them to the cart, and purchase them.

[Source: GCP repo reference](https://github.com/GoogleCloudPlatform/microservices-demo.git)

4. **Deploy a sample microservices-demo app to the cluster.**

```
kubectl apply -f ./release/kubernetes-manifests.yaml
```

5. **Wait for the Pods to be ready.**

```
kubectl get pods
```

After a few minutes, you should see:

```
NAME                                     READY   STATUS    RESTARTS   AGE
adservice-76bdd69666-ckc5j               1/1     Running   0          2m58s
cartservice-66d497c6b7-dp5jr             1/1     Running   0          2m59s
checkoutservice-666c784bd6-4jd22         1/1     Running   0          3m1s
currencyservice-5d5d496984-4jmd7         1/1     Running   0          2m59s
emailservice-667457d9d6-75jcq            1/1     Running   0          3m2s
frontend-6b8d69b9fb-wjqdg                1/1     Running   0          3m1s
loadgenerator-665b5cd444-gwqdq           1/1     Running   0          3m
paymentservice-68596d6dd6-bf6bv          1/1     Running   0          3m
productcatalogservice-557d474574-888kr   1/1     Running   0          3m
recommendationservice-69c56b74d4-7z8r5   1/1     Running   0          3m1s
redis-cart-5f59546cdd-5jnqf              1/1     Running   0          2m58s
shippingservice-6ccc89f8fd-v686r         1/1     Running   0          2m58s
```

7. **Access the web frontend in a browser** using the frontend's `EXTERNAL_IP`.

```
kubectl get service frontend-external | awk '{print $4}'
```

*Example output - do not copy*

```
EXTERNAL-IP
<your-ip>
```


# Canary Deployment (GKE / Istio)

[Reference](https://github.com/GoogleCloudPlatform/istio-samples/tree/master/istio-canary-gke)

In this example, we will learn how to use [Istio’s](https://istio.io/) [Traffic Splitting](https://istio.io/docs/concepts/traffic-management/#splitting-traffic-between-versions) feature to perform a Canary deployment on [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/).

In this sample, `productcatalogservice-v2` introduces a 3-second
[latency](https://github.com/GoogleCloudPlatform/microservices-demo/tree/master/src/productcatalogservice#latency-injection) into all server requests. We’ll show how to use Stackdriver and Istio together to
view the latency difference between the existing `productcatalog` deployment and the
slower v2 deployment.


## Install istio

[Source: GCP repo reference](https://github.com/GoogleCloudPlatform/istio-samples)

1. Change into the Istio install directory from the root of this repository.
```
cd common/
```

2. Install Istio on the cluster:

```
./install_istio.sh
```

3. Once the cluster is ready, ensure that Istio is running:

```
$ kubectl get pods -n istio-system

NAME                                   READY   STATUS    RESTARTS   AGE
grafana-556b649566-fw67z               1/1     Running   0          5m24s
istio-ingressgateway-fc6c9d9df-nmndg   1/1     Running   0          5m30s
istio-tracing-7cf5f46848-qksxq         1/1     Running   0          5m24s
istiod-7b5d6db6b6-b457p                1/1     Running   0          5m48s
kiali-b4b5b4fb8-hwm42                  1/1     Running   0          5m23s
prometheus-558b665bb7-5v647            2/2     Running   0          5m23s
```

## Deploy the Sample App

1.  Add a `version=v1` label to the `productcatalog` deployment

```

kubectl apply -f microservices-demo/release/istio-manifests.yaml

kubectl delete serviceentry allow-egress-google-metadata
kubectl delete serviceentry allow-egress-googleapis


kubectl patch deployments/productcatalogservice -p '{"spec":{"template":{"metadata":{"labels":{"version":"v1"}}}}}'

```

2. Using `kubectl get pods`, verify that all pods are `Running` and `Ready`.

At this point, ProductCatalog v1 is deployed to the cluster, along with the rest of the
demo microservices. You can reach the Hipstershop frontend at the `EXTERNAL_IP` address
output for this command:

```
kubectl get svc -n istio-system istio-ingressgateway
```

## Deploy ProductCatalog v2

1. `cd` into the example directory.

```
cd istio-canary-gke/
```

2. Create an Istio [DestinationRule](https://istio.io/docs/reference/config/istio.networking.v1alpha3/#DestinationRule) for `productcatalogservice`.

```
kubectl apply -f canary/destinationrule.yaml
```

3. Deploy `productcatalog` v2.
```
kubectl apply -f canary/productcatalog-v2.yaml
```

4. Using `kubectl get pods`, verify that the `v2` pod is Running.
```
productcatalogservice-v2-79459dfdff-6qdh4   2/2       Running   0          1m
```

5. Create an Istio [VirtualService](https://istio.io/docs/reference/config/istio.networking.v1alpha3/#VirtualService) to split incoming `productcatalog` traffic between v1 (75%) and v2 (25%).
```
kubectl apply -f canary/vs-split-traffic.yaml
```

6. In a web browser, navigate again to the hipstershop frontend.
7. Refresh the homepage a few times. You should notice that periodically, the frontend is
   slower to load. Let's explore ProductCatalog's latency with Stackdriver.


## View traffic splitting in Kiali

- To install istioctl: https://istio.io/latest/docs/ops/diagnostic-tools/istioctl/


1. Open the Kiali dashboard with the default admin/admin

```
istioctl dashboard kiali &
```

2. Navigate to Service Graph > namespace: `default`

3. Select "Versioned App Graph."
4. In the service graph, zoom in on `productcatalogservice`. You should see that approximately 25% of productcatalog requests are going to `v2`.



# Assigning Pods to Nodes
- https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/

List all pods and its nodes
```
kubectl get pods -o=wide

kubectl label node gke-main-cluster-my-custom-node-pool-deab4e58-hlgd label=gehoumi-demo
kubectl get nodes --show-labels | grep gehoumi
```
Add node selector to the pod
```
nodeSelector:
  label: gehoumi-demo
```
kubectl apply -f istio-samples/istio-canary-gke/canary/productcatalog-v2.yaml


## Cleanup

To avoid incurring additional billing costs, delete the GKE cluster.

```
terraform plan/apply/destroy
```
