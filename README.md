# mbrc
---
![terraform](https://img.shields.io/badge/Hetzner-D50C2D?style=for-the-badge&logo=hetzner&logoColor=white)
![k8s](https://img.shields.io/badge/kubernetes%20-%23326ce5.svg?&style=for-the-badge&logo=kubernetes&logoColor=white)
![terraform](https://img.shields.io/badge/terraform%20-%235835CC.svg?&style=for-the-badge&logo=terraform&logoColor=white)
![terraform](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=Helm&labelColor=0F1689)


This repository enable easy deployment of Kubernetes clusters on Hetzner Cloud using Tales and Terraform. Benefit from scalable, and automated setup, leveraging infrastructure as core principles for efficient management. Simplify Kubernetes deployment and focus on your applications with confidence.

### Terminology
| Terminology | Meaning                   |
|-------------|---------------------------|
| CPN         | Control Panel Node        |
| WKN         | Worker Kubernetes Node    |


### Install tools
```shell
brew install terraform
curl -sL https://talos.dev/install | sh
brew install kubectl
```

### Crate k8s cluster

```shell
terraform init
terraform apply
```
### Save kubeconfig & talosconfig to local machine

```bash
# warning this command remove yours old configurations (if their exists)
terraform output -raw talosconfig > ~/.talos/config
terraform output -raw kubeconfig > ~/.kube/config
```

#### Set Hetzner API token in k8s secrets for CCM

```shell
kubectl create secret generic hcloud -n kube-system --from-literal=token=TOKEN_FROM_HETZNER
```
