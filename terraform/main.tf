# Internal network
resource "hcloud_network" "this" {
  name     = var.cluster_name
  ip_range = "10.0.0.0/16"
  labels = {
    "cluster" = var.cluster_name
  }
}

resource "hcloud_network_subnet" "nodes" {
  network_id   = hcloud_network.this.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

# NLB for Talos OS and Kubernetes
resource "hcloud_load_balancer" "main" {
  name               = "cpn"
  load_balancer_type = "lb11"
  network_zone       = "eu-central"
}

resource "hcloud_load_balancer_target" "main" {
  count = length(hcloud_server.cpn)
  type             = "server"
  load_balancer_id = hcloud_load_balancer.main.id
  server_id        = hcloud_server.cpn[count.index].id
  depends_on = [
    hcloud_server.cpn
  ]
}

resource "hcloud_load_balancer_service" "main-kubectl" {
  load_balancer_id = hcloud_load_balancer.main.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
}

resource "hcloud_load_balancer_service" "main-talosctl" {
  load_balancer_id = hcloud_load_balancer.main.id
  protocol         = "tcp"
  listen_port      = 50000
  destination_port = 50000
}

# Talos OS base configuration
resource "talos_machine_secrets" "this" {}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints = [
    hcloud_load_balancer.main.ipv4
  ]
}

# Control plane nodes
data "talos_machine_configuration" "cpn" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${hcloud_load_balancer.main.ipv4}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  config_patches = [
    templatefile("${path.module}/templates/cpn.yaml.tmpl", {}
    )
  ]
}

resource "hcloud_server" "cpn" {
  name        = "cpn-${format("%02d", count.index)}"
  image       = var.hcloud_image
  count       = var.cpn_count
  server_type = "cpx21"
  location    = var.hcloud_location
  labels = {
    type = "cpn"
  }
  user_data = data.talos_machine_configuration.cpn.machine_configuration
  network {
    network_id = hcloud_network_subnet.nodes.network_id
    ip = cidrhost(hcloud_network_subnet.nodes.ip_range, count.index + 100)
    alias_ips = [] # https://github.com/hetznercloud/terraform-provider-hcloud/issues/650
  }
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  depends_on = [
    data.talos_machine_configuration.cpn,
    hcloud_network_subnet.nodes
  ]
  lifecycle {
    ignore_changes = [
      image,
      user_data,
      network
    ]
  }
}

resource "talos_machine_configuration_apply" "cpn" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.cpn.machine_configuration
  count = length(hcloud_server.cpn)
  node                        = hcloud_server.cpn[count.index].ipv4_address
}

# Worker nodes
data "talos_machine_configuration" "wkn" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${hcloud_load_balancer.main.ipv4}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  config_patches = [
    templatefile("${path.module}/templates/wkn.yaml.tmpl", {})
  ]
}

resource "hcloud_server" "wkn" {
  name        = "wkn-${format("%02d", count.index)}"
  image       = var.hcloud_image
  count       = var.wkn_count
  server_type = "cpx21"
  location    = var.hcloud_location
  labels = {
    type = "wkn"
  }
  user_data = data.talos_machine_configuration.wkn.machine_configuration
  network {
    network_id = hcloud_network_subnet.nodes.network_id
    ip = cidrhost(hcloud_network_subnet.nodes.ip_range, count.index + 200)
    alias_ips = [] # https://github.com/hetznercloud/terraform-provider-hcloud/issues/650
  }
  depends_on = [
    data.talos_machine_configuration.cpn,
    hcloud_network_subnet.nodes
  ]
  lifecycle {
    ignore_changes = [
      image,
      user_data,
      network
    ]
  }
}

resource "talos_machine_configuration_apply" "wkn" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.wkn.machine_configuration
  count = length(hcloud_server.wkn)
  node                        = hcloud_server.wkn[count.index].ipv4_address
}

# Bootstrap the cluster
resource "talos_machine_bootstrap" "bootstrap" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = hcloud_server.cpn[0].ipv4_address
  node                 = hcloud_server.cpn[0].ipv4_address
  depends_on = [
    hcloud_server.cpn
  ]
}

# Configure Kubernetes cluster
resource "helm_release" "cilium" {
  name       = "cilium"
  chart      = "cilium"
  namespace  = "kube-system"
  repository = "https://helm.cilium.io/"
  version    = "1.14.0"

  values = [
    file("manifests/cilium.yaml")
  ]
}

resource "kubernetes_namespace" "flux-system" {
  metadata {
    name = "flux-system"
  }
  depends_on = [
    talos_machine_bootstrap.bootstrap
  ]
}

resource "kubernetes_secret" "sops" {
  metadata {
    name      = "sops-age"
    namespace = "flux-system"
  }
  data = {
    "age.agekey" = file(var.sops_private_key)
  }
  depends_on = [
    kubernetes_namespace.flux-system
  ]
}

resource "kubernetes_namespace" "base-system" {
  metadata {
    name = "base-system"
  }
  depends_on = [
    talos_machine_bootstrap.bootstrap
  ]
}

resource "kubernetes_secret" "hcloud" {
  metadata {
    name      = "hcloud"
    namespace = "kube-system"
  }
  data = {
    token   = var.hcloud_token
    image   = var.hcloud_image
    network = hcloud_network.this.id
  }
  depends_on = [
    talos_machine_bootstrap.bootstrap
  ]
}

# Talos OS and Kubernetes admin config
data "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = hcloud_server.cpn[0].ipv4_address
  wait                 = true
}
