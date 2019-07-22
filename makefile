.PHONY: help
.DEFAULT_GOAL := help
	
export istio-prometheus-version=1.0.6-gke.3
export INGRESS_HOST=$(shell kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

export INGRESS_PORT=$(shell kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(shell kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
export GATEWAY_URL=${INGRESS_HOST}:${INGRESS_PORT}
#export GATEWAY_URL_MINIKUBE=192.168.99.101:31380
export GATEWAY_URL_MINIKUBE=34.77.44.32:80

login: ## login
	gcloud auth application-default login
goto :eof

cluster-data: ## cluster-data
	pulumi config set nodeMachineType n1-standard-1
	pulumi config set nodeCount 3
	pulumi config set password --secret adminadminadminadmin
	pulumi config set gcp:zone europe-west1-b
goto :eof

:book-info
    kubectl label namespace default istio-injection=enabled
    kubectl apply -f istio/samples/bookinfo/platform/kube/bookinfo.yaml
    kubectl apply -f istio/samples/bookinfo/networking/bookinfo-gateway.yaml
    set INGRESS_HOST=(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

install-prometheus: ## install-prometheus
	curl https://storage.googleapis.com/gke-release/istio/release/${istio-prometheus-version}/patches/install-prometheus.yaml | kubectl apply -n istio-system -f -


book-info: ## book-info
	kubectl label namespace default istio-injection=enabled
	kubectl apply -f istio/samples/bookinfo/platform/kube/bookinfo.yaml
	kubectl apply -f istio/samples/bookinfo/networking/bookinfo-gateway.yaml

install-kiali: ## install-kiali
	$(shell bash <(curl -L https://git.io/getLatestKialiOperator))
	  kubectl port-forward svc/kiali 20001:20001 -n istio-system

install-istio-minikube: ## install-istio-minikube
	helm repo add istio.io https://storage.googleapis.com/istio-release/releases/1.2.2/charts/
	kubectl apply -f install/kubernetes/helm/helm-service-account.yaml
	helm init --service-account tiller
	helm install install/kubernetes/helm/istio-init --name istio-init --namespace istio-system
	helm install install/kubernetes/helm/istio --name istio --namespace istio-system --set kiali.enabled=true

call-app: ## install-prometheus
	@echo  $(INGRESS_HOST)
	curl -s http://${GATEWAY_URL}/api/v1/products
	curl -s http://${GATEWAY_URL}/productpage | grep -o "<title>.*</title>" && $(MAKE) call-app 	

call-app-minikube: ## install-prometheus
	@echo  $(INGRESS_HOST)
	curl -s http://${GATEWAY_URL_MINIKUBE}/api/v1/products
	curl -s http://${GATEWAY_URL_MINIKUBE}/productpage | grep -o "<title>.*</title>" && $(MAKE) call-app-minikube




help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
