variable "hcloud_api_token" {
  type        = string
  description = "Hetzner Cloud API token"
  default     = ""
}

variable "wg_server_name" {
  type        = string
  description = "Server name"
  default     = "wireguard"
}

variable "wg_server_type" {
  type        = string
  description = "Server type"
  default     = "cx11"
}

variable "wg_server_location" {
  type        = string
  description = "Server location"
  default     = "fsn1"
}

variable "wg_server_ssh_publickey" {
  type        = string
  description = "SSH public key"
}

variable "wg_server_ssh_publickey_name" {
  type        = string
  description = "SSH public key name"
}

variable "wg_server_own_privatekey" {
  type        = string
  description = "WireGuard private key"
}

variable "wg_server_peer_publickeys" {
  type        = list(string)
  description = "WireGuard peer public keys"
}
