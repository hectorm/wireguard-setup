build {
  sources = [
    "source.hcloud.main"
  ]

  provisioner "file" {
    direction = "upload"
    source = "./rootfs/"
    destination = "/"
  }

  provisioner "shell" {
    inline = [
      "chmod 644 /etc/apt/apt.conf.d/20auto-upgrades",
      "chmod 644 /etc/apt/apt.conf.d/50unattended-upgrades",
      "chmod 644 /etc/fail2ban/jail.d/sshd.conf",
      "chmod 644 /etc/ssh/sshd_config",
      "chmod 644 /etc/unbound/unbound.conf",
      "chmod 644 /etc/wireguard/client-sample.conf",
      "chmod 644 /etc/wireguard/wg0-peers.conf",
      "chmod 600 /etc/wireguard/wg0.conf"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "printf 'deb http://ppa.launchpad.net/wireguard/wireguard/ubuntu/ bionic main\n' > /etc/apt/sources.list.d/wireguard.list",
      "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E1B39B6EF6DDB96564797591AE33835F504A1A25",
      "apt-get update",
      "apt-get upgrade -yo DPkg::options::=--force-confold",
      "apt-get install -yo DPkg::options::=--force-confold dns-root-data fail2ban ufw unattended-upgrades unbound",
      "apt-get install -yo DPkg::options::=--force-confold linux-headers-$(uname -r) openresolv wireguard",
      "apt-get install -yo DPkg::options::=--force-confold htop iperf3 qrencode nano ssh-import-id",
      "apt-get autoremove -y"
    ]
  }

  provisioner "shell" {
    inline = [
      "systemctl disable --now systemd-resolved.service",
      "unlink /etc/resolv.conf && printf 'nameserver 127.0.0.1\n' > /etc/resolv.conf",
      "systemctl enable --now unbound.service unbound-resolvconf.service",
    ]
  }

  provisioner "shell" {
    inline = [
      "systemctl enable --now fail2ban.service ufw.service unattended-upgrades.service",
      "systemctl enable --now wg-quick@wg0.service"
    ]
  }

  provisioner "shell" {
    inline = [
      "ufw --force enable",
      "ufw default deny incoming",
      "ufw default allow outgoing",
      "ufw allow from any to any port 22 proto tcp"
    ]
  }

  provisioner "shell" {
    inline = [
      "groupadd -r ssh-user",
      "usermod -aG ssh-user root",
      "passwd -d root"
    ]
  }

  provisioner "shell" {
    inline = [
      "rm -f /etc/ssh/ssh_host_*key*",
      "rm -f /etc/wireguard/*-*key",
      "rm -f /etc/wireguard/*-iface",
      "rm -rf /var/lib/apt/lists/*"
    ]
  }
}
