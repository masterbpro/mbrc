variable "hcloud_token" {
  default = ""
}

variable "hcloud_image" {
  default = ""
}

variable "cluster_name" {
  default = "mbrc"
}

variable "hcloud_location" {
  default = "hel1" # https://docs.hetzner.com/cloud/general/locations/
}

variable "cpn_count" {
  default = 3
}

variable "wkn_count" {
  default = 2
}

variable "sops_private_key" {
  default = "../age.agekey"
}
