variable "hcloud_api_token" {
  type        = string
  description = "Hetzner Cloud API token"
  default     = "xxxx"
}

variable "digitalocean_api_token" {
  type        = string
  description = "DigitalOcean API token"
  default     = "xxxx"
}

variable "qemu_accelerator" {
  type        = string
  description = "The accelerator type to use when running the VM"
  default     = "kvm"
}
