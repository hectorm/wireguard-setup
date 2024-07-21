source "hcloud" "main" {
  token = var.hcloud_api_token

  image       = "ubuntu-24.04"
  server_name = "wireguard-{{timestamp}}"
  server_type = "cax11"
  location    = "fsn1"

  snapshot_name = "wireguard-{{timestamp}}"
  snapshot_labels = {
    service = "wireguard"
  }

  user_data_file = "./hetzner/seed/user-data"

  ssh_port                  = "22"
  ssh_username              = "root"
  ssh_timeout               = "30m"
  ssh_clear_authorized_keys = true
}

source "digitalocean" "main" {
  api_token = var.digitalocean_api_token

  image        = "ubuntu-24-04-x64"
  droplet_name = "wireguard-{{timestamp}}"
  size         = "s-1vcpu-512mb-10gb"
  region       = "ams3"

  snapshot_name = "wireguard-{{timestamp}}"
  tags = [
    "wireguard"
  ]

  user_data_file = "./digitalocean/seed/user-data"

  ssh_port                  = "22"
  ssh_username              = "root"
  ssh_timeout               = "30m"
  ssh_clear_authorized_keys = true
}

source "qemu" "main" {
  iso_url = "https://cloud-images.ubuntu.com/minimal/daily/noble/current/noble-minimal-cloudimg-${
    var.qemu_binary == "qemu-system-aarch64" ? "arm64" : "amd64"
  }.img"
  iso_checksum = "file:https://cloud-images.ubuntu.com/minimal/daily/noble/current/SHA256SUMS"
  disk_image   = true

  vm_name          = "wireguard.qcow2"
  http_directory   = "./qemu/http/"
  output_directory = "./dist/qemu/"

  headless     = true
  accelerator  = var.qemu_binary == "qemu-system-aarch64" ? "none" : null
  machine_type = var.qemu_binary == "qemu-system-aarch64" ? "virt,gic-version=3" : "q35"
  cpu_model    = var.qemu_binary == "qemu-system-aarch64" ? "cortex-a76" : null
  cpus         = 2
  memory       = 1024
  qemu_binary  = var.qemu_binary
  qemuargs = [
    ["-smbios", "type=1,serial=ds=nocloud;s=http://{{.HTTPIP}}:{{.HTTPPort}}/seed/"]
  ]
  efi_firmware_code = var.qemu_efi_firmware_code
  efi_firmware_vars = var.qemu_efi_firmware_vars

  net_device = "virtio-net"

  format           = "qcow2"
  disk_size        = "4G"
  disk_interface   = "virtio"
  disk_compression = false

  ssh_port                  = "22"
  ssh_username              = "root"
  ssh_password              = "toor"
  ssh_timeout               = "30m"
  ssh_clear_authorized_keys = true

  shutdown_command = "shutdown -P now"
}

source "qemu" "baremetal" {
  iso_url = "https://cdimage.ubuntu.com/ubuntu-server/noble/daily-live/current/noble-live-server-${
    var.qemu_binary == "qemu-system-aarch64" ? "arm64" : "amd64"
  }.iso"
  iso_checksum = "file:https://cdimage.ubuntu.com/ubuntu-server/noble/daily-live/current/SHA256SUMS"
  disk_image   = false

  vm_name          = "wireguard.qcow2"
  http_directory   = "./qemu/http/"
  output_directory = "./dist/qemu-baremetal/"

  headless     = true
  accelerator  = var.qemu_binary == "qemu-system-aarch64" ? "none" : null
  machine_type = var.qemu_binary == "qemu-system-aarch64" ? "virt,gic-version=3" : "q35"
  cpu_model    = var.qemu_binary == "qemu-system-aarch64" ? "cortex-a76" : null
  cpus         = 2
  memory       = 1024
  qemu_binary  = var.qemu_binary
  qemuargs = var.qemu_binary == "qemu-system-aarch64" ? [
    ["-monitor", "none"],
    ["-boot", "strict=off"],
    ["-device", "virtio-gpu-pci"],
    ["-device", "qemu-xhci,id=usb"],
    ["-device", "usb-kbd,id=input0,bus=usb.0,port=1"]
  ] : []
  efi_firmware_code = var.qemu_efi_firmware_code
  efi_firmware_vars = var.qemu_efi_firmware_vars

  net_device = "virtio-net"

  format           = "qcow2"
  disk_size        = "4G"
  disk_interface   = "virtio"
  disk_compression = false

  boot_wait = "25s"
  boot_command = [
    "c<wait>",
    "set gfxpayload=keep<enter><wait>",
    "linux /casper/vmlinuz --- autoinstall ds='nocloud;s=http://{{.HTTPIP}}:{{.HTTPPort}}/seed-autoinstall/'<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  ssh_port                  = "22"
  ssh_username              = "root"
  ssh_password              = "toor"
  ssh_timeout               = "60m"
  ssh_clear_authorized_keys = true

  shutdown_command = "shutdown -P now"
}
