# mbrc

![terraform](https://img.shields.io/badge/Hetzner-D50C2D?style=for-the-badge&logo=hetzner&logoColor=white)
![k8s](https://img.shields.io/badge/kubernetes%20-%23326ce5.svg?&style=for-the-badge&logo=kubernetes&logoColor=white)
![terraform](https://img.shields.io/badge/terraform%20-%235835CC.svg?&style=for-the-badge&logo=terraform&logoColor=white)
![helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=Helm&labelColor=0F1689)
![cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=Cloudflare&logoColor=white)

This repository enable easy deployment of Kubernetes clusters on Hetzner Cloud using Talos OS and Terraform. Benefit
from
scalable, and automated setup, leveraging infrastructure as core principles for efficient management. Simplify
Kubernetes deployment and focus on your applications with confidence.

### Terminology

| Terminology | Meaning                |
| ----------- | ---------------------- |
| CPN         | Control Plane Node     |
| WKN         | Worker Kubernetes Node |

### 0. Install tools

```shell
brew install age
brew install terraform
curl -sL https://talos.dev/install | sh
brew install kubectl
```

### 1. Prepare environments variables

```shell
# you need change values before execute command
cat << EOF > terraform/terraform.tfvars
hcloud_token = "YOUR_TOKEN_FROM_HETZNER"
hcloud_image = 1234567890
cf_token     = "YOUR_TOKEN_FROM_CLOUDFLARE"
wkn_count    = 0
EOF
```

### 2. Create private and public key for SOPS

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
to encrypt their secrets using the public key. Remember, keep the `age.agekey` private key secure.

### 3. Create k8s cluster

Before enter command bellow you need prepare Talos snapshot in Hetzner Cloud. For this, you can use
official [instruction](https://www.talos.dev/v1.6/talos-guides/install/cloud-platforms/hetzner/#rescue-mode).
You have to give the name of the snapshot `talos-1.15`

```shell
terraform init
terraform apply
```

### 4. Save kubeconfig & talosconfig to local machine

```bash
# Warning! This command remove yours old configurations (if their exists)

terraform output -raw talosconfig > ~/.talos/config
terraform output -raw kubeconfig > ~/.kube/config
```

### 5. Done 🎉

```shell
# you can check cluster status via `kubectl get nodes`.
# Output will be something like this:

(base) user@host terraform % kubectl get nodes
NAME     STATUS   ROLES           AGE   VERSION
cpn-00   Ready    control-plane   25m   v1.28.1
cpn-01   Ready    control-plane   25m   v1.28.1
cpn-02   Ready    control-plane   25m   v1.28.1
```

---

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

# You can decrypt it only if you have the age.agekey file.
export SOPS_AGE_KEY_FILE=age.agekey
sops -i -d db-auth.yaml.yaml
```

</details>

<details>
<summary>FluxCD Example</summary>

```shell

export GITHUB_TOKEN=ghp-xyz
flux bootstrap github --owner=ownerName --repository=mbrc --path=kubernetes/flux
```

```shell
export GITLAB_TOKEN=glpat-xyz
flux bootstrap gitlab --owner=groupName --repository=mbrc --path=kubernetes/flux
```

</details>
