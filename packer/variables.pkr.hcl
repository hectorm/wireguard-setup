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

variable "qemu_binary" {
  type        = string
  description = "QEMU binary path"
  default     = "qemu-system-x86_64"
  # default   = "qemu-system-aarch64"
}

variable "qemu_efi_firmware_code" {
  type        = string
  description = "EFI firmware file"
  default     = "/usr/share/edk2/x64/OVMF_CODE.4m.fd"
  # default   = "/usr/share/AAVMF/AAVMF_CODE.fd"
}

variable "qemu_efi_firmware_vars" {
  type        = string
  description = "EFI NVRAM variables file"
  default     = "/usr/share/edk2/x64/OVMF_VARS.4m.fd"
  # default   = "/usr/share/AAVMF/AAVMF_VARS.fd"
}
