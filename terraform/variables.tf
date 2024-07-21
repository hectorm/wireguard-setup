variable "hcloud_api_token" {
  type        = string
  description = "Hetzner Cloud API token"
  default     = "xxxx"
}

variable "wg_server_name" {
  type        = string
  description = "Server name"
  default     = "wireguard"
}

variable "wg_server_type" {
  type        = string
  description = "Server type"
  default     = "cax11"
}

variable "wg_server_location" {
  type        = string
  description = "Server location"
  default     = "fsn1"
}

variable "wg_server_wg_privatekey" {
  type        = string
  description = "WireGuard private key"
  default     = ""
}

variable "wg_server_wg_peers" {
  type = list(object({
    comment      = optional(string, "")
    publickey    = string
    presharedkey = string
  }))
  description = "WireGuard peers"
  default     = []
}

variable "wg_firewall_name" {
  type        = string
  description = "Firewall name"
  default     = "wireguard"
}

variable "wg_ssh_publickey" {
  type        = string
  description = "SSH public key"
}

variable "wg_ssh_publickey_name" {
  type        = string
  description = "SSH public key name"
}
