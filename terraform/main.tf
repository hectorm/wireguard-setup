terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.36.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_api_token
}

data "hcloud_image" "wg_image" {
  with_selector = "service=wireguard"
  most_recent   = true
}

resource "hcloud_firewall" "wg_firewall" {
  name   = var.wg_firewall_name
  labels = { service = "wireguard" }
  rule {
    description = "ICMP"
    direction   = "in"
    protocol    = "icmp"
    source_ips  = ["0.0.0.0/0", "::0/0"]
  }
  rule {
    description = "SSH"
    direction   = "in"
    protocol    = "tcp"
    port        = "122"
    source_ips  = ["0.0.0.0/0", "::0/0"]
  }
  rule {
    description = "WireGuard"
    direction   = "in"
    protocol    = "udp"
    port        = "51820"
    source_ips  = ["0.0.0.0/0", "::0/0"]
  }
  rule {
    description = "WireGuard"
    direction   = "in"
    protocol    = "udp"
    port        = "53"
    source_ips  = ["0.0.0.0/0", "::0/0"]
  }
  rule {
    description = "WireGuard"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = ["0.0.0.0/0", "::0/0"]
  }
}

resource "hcloud_ssh_key" "wg_ssh_key" {
  public_key = var.wg_ssh_publickey
  name       = var.wg_ssh_publickey_name
}

resource "hcloud_server" "wg_server" {
  image        = data.hcloud_image.wg_image.id
  name         = var.wg_server_name
  server_type  = var.wg_server_type
  location     = var.wg_server_location
  labels       = { service = "wireguard" }
  firewall_ids = [hcloud_firewall.wg_firewall.id]
  ssh_keys     = [hcloud_ssh_key.wg_ssh_key.id]
  user_data = templatefile("${path.module}/templates/user-data.tpl", {
    wg_server_wg_privatekey      = var.wg_server_wg_privatekey
    wg_server_wg_peer_publickeys = var.wg_server_wg_peer_publickeys
  })
}
