source "hcloud" "main" {
  image = "ubuntu-18.04"
  server_name = "wireguard-{{timestamp}}"
  server_type = "cx11"
  location = "fsn1"

  snapshot_name = "wireguard-{{timestamp}}"
  snapshot_labels {
    service = "wireguard"
  }

  ssh_port = "22"
  ssh_username = "root"
  ssh_timeout = "10m"
}

source "qemu" "main" {
  iso_url = "https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img"
  iso_checksum_url = "https://cloud-images.ubuntu.com/bionic/current/SHA256SUMS"
  iso_checksum_type = "sha256"
  disk_image = true

  vm_name = "wireguard.qcow2"
  http_directory = "./qemu/http/"
  output_directory = "./qemu/dist/"

  accelerator = "kvm"
  cpus = 1
  memory = 512
  headless = true
  qemuargs = [
    ["-smbios", "type=1,serial=ds=nocloud-net;s=http://{{.HTTPIP}}:{{.HTTPPort}}/seed/"]
  ]

  net_device = "virtio-net"

  format = "qcow2"
  disk_size = "4G"
  disk_interface = "virtio"
  disk_compression = false

  ssh_port = "22"
  ssh_username = "root"
  ssh_password = "toor"
  ssh_timeout = "10m"

  shutdown_command = "shutdown -P now"
}
