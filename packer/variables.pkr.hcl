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

variable "oracle_key_file" {
  type        = string
  description = "Oracle Cloud API signing key file"
  default     = "~/.oci/oci_api_key.pem"
}

variable "oracle_availability_domain" {
  type        = string
  description = "Availability domain name"
  default     = "xxxx:EU-FRANKFURT-1-AD-1"
}

variable "oracle_compartment_ocid" {
  type        = string
  description = "Compartment OCID"
  default     = "ocid1.tenancy.xxxx"
}

variable "oracle_subnet_ocid" {
  type        = string
  description = "Subnet OCID"
  default     = "ocid1.subnet.xxxx"
}

variable "qemu_accelerator" {
  type        = string
  description = "The accelerator type to use when running the VM"
  default     = "kvm"
}
