provider "hcloud" {
  token = var.hcloud_api_token
}

data "hcloud_image" "wg_image" {
  with_selector = "service=wireguard"
  most_recent   = true
}

resource "hcloud_ssh_key" "wg_server_ssh_key" {
  public_key = var.wg_server_ssh_publickey
  name       = var.wg_server_ssh_publickey_name
}

resource "hcloud_server" "wg_server" {
  image       = data.hcloud_image.wg_image.id
  name        = var.wg_server_name
  server_type = var.wg_server_type
  location    = var.wg_server_location
  labels = {
    service = "wireguard"
  }
  ssh_keys = [
    hcloud_ssh_key.wg_server_ssh_key.id
  ]
  user_data = templatefile("${path.module}/templates/user-data.tpl", {
    wg_server_own_privatekey  = var.wg_server_own_privatekey
    wg_server_peer_publickeys = var.wg_server_peer_publickeys
  })
}
