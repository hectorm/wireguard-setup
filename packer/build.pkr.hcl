build {
  sources = [
    "source.hcloud.main",
    "source.digitalocean.main",
    "source.qemu.main"
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
        find /tmp/rootfs/ -type f -name .gitkeep -delete
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
        apt-get install -y --no-install-recommends \
          ca-certificates \
          dns-root-data \
          gcc \
          git \
          htop \
          libc6-dev \
          libsystemd-dev \
          linux-virtual-hwe-20.04 \
          make \
          nano \
          nftables \
          openresolv \
          pkgconf \
          qrencode \
          rng-tools \
          ssh-import-id \
          unattended-upgrades \
          unbound \
          wireguard
      EOF
      ,
      <<EOF
        apt-get purge -y \
          accountsservice \
          packagekit \
          snapd
        apt-get autoremove -y
      EOF
      ,
      <<EOF
        mkdir /usr/local/src/udptunnel/ && cd /usr/local/src/udptunnel/
        git clone 'https://github.com/hectorm/udptunnel.git' ./
        git checkout '13578016f47b2f02e85c5ab4aa92e820e1f25f79'
        PREFIX=/usr/local ./udptunnel-installer.sh
        udptunnel --help
      EOF
      ,
      <<EOF
        systemctl disable --now systemd-resolved.service
        unlink /etc/resolv.conf && printf 'nameserver 127.0.0.1\n' > /etc/resolv.conf
        systemctl enable --now unbound.service unbound-resolvconf.service
      EOF
      ,
      <<EOF
        systemctl enable --now nftables.service rng-tools.service ssh.service
        systemctl enable --now apt-daily-upgrade.timer apt-daily.timer unattended-upgrades.service
        systemctl enable udptunnel.service wg-quick@wg0.service
      EOF
      ,
      <<EOF
        groupadd -r ssh-user
        usermod -aG ssh-user root
        usermod -p '*' root
      EOF
      ,
      <<EOF
        rm -f /etc/ssh/ssh_host_*key*
        rm -f /etc/wireguard/*-*key /etc/wireguard/*-iface
        find /var/lib/apt/lists/ -mindepth 1 -delete
        find / -type f -regex '.+\.\(dpkg\|ucf\)-\(old\|new\|dist\)' -ignore_readdir_race -delete ||:
      EOF
    ]
  }
}
