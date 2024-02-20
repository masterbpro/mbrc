terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.44.1"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.17.0"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.3.4"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.11.0"
    }

  }
}


provider "hcloud" {
  token = var.hcloud_token
}


provider "helm" {
  kubernetes {
    host                   = data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.host
    client_certificate     = base64decode(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
  }
}
