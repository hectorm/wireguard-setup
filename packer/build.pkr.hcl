build {
  sources = [
    "source.hcloud.main"
  ]

  provisioner "file" {
    direction = "upload"
    source = "./rootfs"
    destination = "/tmp"
  }

  provisioner "shell" {
    environment_vars = [
      "DPKG_FORCE=confold",
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline_shebang = "/bin/sh -eux"
    inline = [
      <<EOF
        find /tmp/rootfs/ -type d -exec chmod 755 '{}' ';' -exec chown root:root '{}' ';'
        find /tmp/rootfs/ -type f -exec chmod 644 '{}' ';' -exec chown root:root '{}' ';'
        find /tmp/rootfs/ -type f -regex '.+/\(bin\|cron\..+\)/.+' -exec chmod 755 '{}' ';'
        find /tmp/rootfs/ -mindepth 1 -maxdepth 1 -exec cp -rfla '{}' / ';'
        rm -rf /tmp/rootfs/
      EOF
      ,
      <<EOF
        printf 'deb http://ppa.launchpad.net/wireguard/wireguard/ubuntu/ bionic main\n' > /etc/apt/sources.list.d/wireguard.list
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E1B39B6EF6DDB96564797591AE33835F504A1A25
        apt-get update
        apt-get upgrade -yo DPkg::options::=--force-confold
        apt-get install -yo DPkg::options::=--force-confold dns-root-data fail2ban ufw unattended-upgrades unbound
        apt-get install -yo DPkg::options::=--force-confold linux-headers-$(uname -r) openresolv wireguard
        apt-get install -yo DPkg::options::=--force-confold htop iperf3 qrencode nano ssh-import-id
        apt-get autoremove -y
      EOF
      ,
      <<EOF
        systemctl disable --now systemd-resolved.service
        unlink /etc/resolv.conf && printf 'nameserver 127.0.0.1\n' > /etc/resolv.conf
        systemctl enable --now unbound.service unbound-resolvconf.service
      EOF
      ,
      <<EOF
        systemctl enable --now fail2ban.service ufw.service unattended-upgrades.service
        systemctl enable --now wg-quick@wg0.service
      EOF
      ,
      <<EOF
        ufw --force enable
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow from any to any port 22 proto tcp
      EOF
      ,
      <<EOF
        groupadd -r ssh-user
        usermod -aG ssh-user root
        passwd -d root
      EOF
      ,
      <<EOF
        rm -f /etc/ssh/ssh_host_*key*
        rm -f /etc/wireguard/*-*key
        rm -f /etc/wireguard/*-iface
        rm -rf /var/lib/apt/lists/*
      EOF
    ]
  }
}
