build {
  sources = [
    "source.hcloud.main",
    "source.digitalocean.main",
    "source.qemu.main"
  ]

  provisioner "file" {
    direction   = "upload"
    source      = "./rootfs"
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
        apt-get dist-upgrade -o DPkg::Lock::Timeout=300 -y
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
          make \
          nano \
          nftables \
          openresolv \
          pkgconf \
          qrencode \
          rng-tools5 \
          ssh-import-id \
          unattended-upgrades \
          unbound \
          wireguard
      EOF
      ,
      <<EOF
        apt-get purge -y \
          lxd-agent-loader \
          snapd
        apt-get autoremove -y
      EOF
      ,
      <<EOF
        mkdir /usr/local/src/udptunnel/ && cd /usr/local/src/udptunnel/
        git clone 'https://github.com/hectorm/udptunnel.git' ./
        git checkout '0739600886ae05a67b6921d4154237cfdd109dd4'
        ./udptunnel-installer.sh PREFIX=/usr/local
        udptunnel --help
      EOF
      ,
      <<EOF
        systemctl mask --now systemd-resolved.service
        unlink /etc/resolv.conf && printf 'nameserver 127.0.0.1\n' > /etc/resolv.conf
        systemctl enable --now unbound.service unbound-resolvconf.service
      EOF
      ,
      <<EOF
        systemctl enable --now nftables.service rngd.service ssh.service
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
        rm -rf /etc/ssh/ssh_host_*key* /root/.ssh/ /etc/wireguard/*-*key /root/snap/
        find /tmp/ /var/tmp/ /var/lib/apt/lists/ -ignore_readdir_race -mindepth 1 -delete ||:
        find / -type f -regex '.+\.\(dpkg\|ucf\)-\(old\|new\|dist\)' -delete ||:
        journalctl --rotate && journalctl --vacuum-time=1s
        cloud-init clean --logs
      EOF
    ]
  }
}
