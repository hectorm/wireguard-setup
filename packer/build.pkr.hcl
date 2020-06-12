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
        find /tmp/rootfs/ -type f -regex '.+/\(etc/wireguard\)/.+' -exec chmod 600 '{}' ';'
        find /tmp/rootfs/ -mindepth 1 -maxdepth 1 -exec cp -fla '{}' / ';'
        rm -rf /tmp/rootfs/
      EOF
      ,
      <<EOF
        systemctl daemon-reload
      EOF
      ,
      <<EOF
        timedatectl set-timezone UTC
        localectl set-locale LANG=en_US.UTF-8
      EOF
      ,
      <<EOF
        apt-get update
        apt-get dist-upgrade -y
      EOF
      ,
      <<EOF
        apt-get purge -y \
          snapd
        apt-get install -y \
          dns-root-data \
          fail2ban \
          htop \
          iperf3 \
          nano \
          openresolv \
          qrencode \
          rng-tools \
          ssh-import-id \
          ufw \
          unattended-upgrades \
          unbound \
          wireguard
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
        systemctl enable --now fail2ban.service rng-tools.service ssh.service ufw.service
        systemctl enable --now apt-daily-upgrade.timer apt-daily.timer unattended-upgrades.service
        systemctl enable wg-quick@wg0.service
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
        groupadd --system ssh-user
        usermod --append --groups ssh-user root
        passwd -d root
      EOF
      ,
      <<EOF
        rm -f /etc/ssh/ssh_host_*key*
        rm -f /etc/wireguard/*-*key /etc/wireguard/*-iface
        find /var/lib/apt/lists/ -mindepth 1 -delete
        find / -ignore_readdir_race -type f -regex '.+\.\(dpkg\|ucf\)-\(old\|new\|dist\)' -delete
      EOF
    ]
  }
}
