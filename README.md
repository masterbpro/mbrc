# mbrc
---

### Crate k8s cluster

```shell
terraform init
terraform apply
```
### Save kubeconfig & talosconfig to local machine

```bash
terraform output -raw talosconfig > talosconfig
terraform output -raw kubeconfig > kubeconfig
```

#### Set Hetzner API token in k8s secrets for CCM

```shell
kubectl create secret generic hcloud -n kube-system --from-literal=token=TOKEN_FROM_HETZNER
```



