source "hcloud" "main" {
  token = var.hcloud_api_token

  image       = "ubuntu-22.04"
  server_name = "wireguard-{{timestamp}}"
  server_type = "cx11"
  location    = "fsn1"

  snapshot_name = "wireguard-{{timestamp}}"
  snapshot_labels = {
    service = "wireguard"
  }

  user_data_file = "./hetzner/seed/user-data"

  ssh_port                  = "22"
  ssh_username              = "root"
  ssh_timeout               = "15m"
  ssh_clear_authorized_keys = true
}

source "digitalocean" "main" {
  api_token = var.digitalocean_api_token

  image        = "ubuntu-22-04-x64"
  droplet_name = "wireguard-{{timestamp}}"
  size         = "s-1vcpu-512mb-10gb"
  region       = "fra1"

  snapshot_name = "wireguard-{{timestamp}}"
  tags = [
    "wireguard"
  ]

  user_data_file = "./digitalocean/seed/user-data"

  ssh_port                  = "22"
  ssh_username              = "root"
  ssh_timeout               = "15m"
  ssh_clear_authorized_keys = true
}

source "oracle-oci" "main" {
  key_file = var.oracle_key_file

  base_image_filter {
    operating_system         = "Canonical Ubuntu"
    operating_system_version = "22.04 Minimal aarch64"
  }
  instance_name = "wireguard-{{timestamp}}"
  shape         = "VM.Standard.A1.Flex"
  shape_config {
    ocpus         = 1
    memory_in_gbs = 1
  }
  availability_domain = var.oracle_availability_domain
  compartment_ocid    = var.oracle_compartment_ocid
  subnet_ocid         = var.oracle_subnet_ocid

  image_name = "wireguard-{{timestamp}}"
  tags = {
    service = "wireguard"
  }

  user_data_file = "./oracle/seed/user-data"

  ssh_port                  = "22"
  ssh_username              = "root"
  ssh_timeout               = "15m"
  ssh_clear_authorized_keys = true
}

source "qemu" "main" {
  iso_url      = "https://cloud-images.ubuntu.com/minimal/daily/jammy/current/jammy-minimal-cloudimg-amd64.img"
  iso_checksum = "file:https://cloud-images.ubuntu.com/minimal/daily/jammy/current/SHA256SUMS"
  disk_image   = true

  vm_name          = "wireguard.qcow2"
  http_directory   = "./qemu/http/"
  output_directory = "./dist/qemu/"

  headless     = true
  accelerator  = "kvm"
  machine_type = "q35"
  cpu_model    = "host"
  cpus         = 1
  memory       = 512
  qemuargs = [
    ["-smbios", "type=1,serial=ds=nocloud-net;s=http://{{.HTTPIP}}:{{.HTTPPort}}/seed/"]
  ]

  net_device = "virtio-net"

  format           = "qcow2"
  disk_size        = "4G"
  disk_interface   = "virtio"
  disk_compression = false

  ssh_port                  = "22"
  ssh_username              = "root"
  ssh_password              = "toor"
  ssh_timeout               = "10m"
  ssh_clear_authorized_keys = true

  shutdown_command = "shutdown -P now"
}
