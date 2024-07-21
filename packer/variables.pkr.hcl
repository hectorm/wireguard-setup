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

variable "qemu_efi_firmware_code" {
  type        = string
  description = "EFI firmware file"
  default     = "/usr/share/edk2/x64/OVMF_CODE.4m.fd"
}

variable "qemu_efi_firmware_vars" {
  type        = string
  description = "EFI NVRAM variables file"
  default     = "/usr/share/edk2/x64/OVMF_VARS.4m.fd"
}
