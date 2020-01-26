variable "hcloud_token" {
  type = string
}

provider "hcloud" {
  token = var.hcloud_token
}

data "hcloud_image" "wireguard" {
  with_selector = "service=wireguard"
  most_recent = true
}

data "hcloud_ssh_key" "hectorm" {
  fingerprint = "a1:92:f2:2b:57:5e:cc:9c:5a:0c:f4:33:79:db:b6:56"
}

resource "hcloud_server" "wireguard" {
  name = "wireguard"
  image = data.hcloud_image.wireguard.id
  server_type = "cx11"
  location = "fsn1"
  keep_disk = true
  backups = false
  labels = {
    service = "wireguard"
  }
  ssh_keys = [
    data.hcloud_ssh_key.hectorm.id
  ]
}

output "wireguard_server_ipv4_address" {
  value = hcloud_server.wireguard.ipv4_address
}
