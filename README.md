# mbrc
---
![terraform](https://img.shields.io/badge/Hetzner-D50C2D?style=for-the-badge&logo=hetzner&logoColor=white)
![k8s](https://img.shields.io/badge/kubernetes%20-%23326ce5.svg?&style=for-the-badge&logo=kubernetes&logoColor=white)
![terraform](https://img.shields.io/badge/terraform%20-%235835CC.svg?&style=for-the-badge&logo=terraform&logoColor=white)
![helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=Helm&labelColor=0F1689)
![cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=Cloudflare&logoColor=white)

This repository enable easy deployment of Kubernetes clusters on Hetzner Cloud using Tales and Terraform. Benefit from
scalable, and automated setup, leveraging infrastructure as core principles for efficient management. Simplify
Kubernetes deployment and focus on your applications with confidence.

### Terminology

| Terminology | Meaning                |
|-------------|------------------------|
| CPN         | Control Panel Node     |
| WKN         | Worker Kubernetes Node |

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

### Create private and public key for SOPS

```shell
age-keygen -o age.agekey && 
age_pubkey=$(awk '/^# public key:/{print $NF}' age.agekey) &&
echo "
creation_rules:
  - path_regex: .*.ya?ml
    encrypted_regex: ^(data|stringData)$
    age: $age_pubkey" > .sops.yaml
```

Next, you'll need to include `.sops.yaml` in your repository. This step is crucial to allow other project contributors
to
encrypt their secrets using the public key. Remember, keep the `age.agekey` private key secure.

Additionally, for Kubernetes to decrypt our secrets, we'll place our private key in Kubernetes:

```shell
kubeclt create namespace flux-system
kubectl create secret generic sops-age --namespace=flux-system --from-file=age.agekey
```

<details>
<summary>SOPS Example</summary>

```yaml
# db-auth.yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-auth
  namespace: default
type: Opaque
data:
  DB_NAME: cG9zdGdyZXM=
  DB_HOST: MTI3LjAuMC4x
  DB_PORT: NTQzMg==
  DB_USERNAME: cG9zdGdyZXM=
  DB_PASSWORD: c3VwZXJTZWNyZXRQYXNzb3dyZA==
```

```shell
# You can encrypt any files by using the .sops.yaml file.
sops -e -i db-auth.yaml

# You can decrypt it only if you have the age.age key file.
export SOPS_AGE_KEY_FILE=age.agekey
sops -i -d db-auth.yaml.yaml
```

</details>
