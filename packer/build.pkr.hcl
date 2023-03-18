build {
  sources = [
    "source.hcloud.main",
    "source.digitalocean.main",
    "source.oracle-oci.main",
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
      # Set permissions and move files to "/"
      <<-EOT
        find /tmp/rootfs/ -type f -name .gitkeep -delete
        find /tmp/rootfs/ -type d -exec chmod 755 '{}' ';' -exec chown root:root '{}' ';'
        find /tmp/rootfs/ -type f -exec chmod 644 '{}' ';' -exec chown root:root '{}' ';'
        find /tmp/rootfs/ -type f -regex '.+/bin/.+' -exec chmod 755 '{}' ';'
        find /tmp/rootfs/ -type f -regex '.+/etc/wireguard/.+' -exec chmod 600 '{}' ';'
        find /tmp/rootfs/ -mindepth 1 -maxdepth 1 -exec cp -fla '{}' / ';'
        rm -rf /tmp/rootfs/
      EOT
      ,
      # Reload systemd manager configuration
      <<-EOT
        systemctl daemon-reload
      EOT
      ,
      # Upgrade system
      <<-EOT
        apt-get update
        apt-get dist-upgrade -o DPkg::Lock::Timeout=300 -o APT::Get::Always-Include-Phased-Updates=true -y
      EOT
      ,
      # Install packages
      <<-EOT
        apt-get install -y --no-install-recommends \
          apparmor \
          apparmor-profiles \
          apparmor-utils \
          apt-utils \
          ca-certificates \
          dns-root-data \
          gcc \
          git \
          htop \
          libc6-dev \
          libsystemd-dev \
          locales \
          make \
          nano \
          nftables \
          openresolv \
          pkgconf \
          qrencode \
          ssh-import-id \
          unattended-upgrades \
          unbound \
          wireguard
      EOT
      ,
      # Remove packages
      <<-EOT
        apt-get purge -y \
          lxd-agent-loader \
          snapd \
          ufw
        apt-get autoremove -y
      EOT
      ,
      # Set timezone and locale
      <<-EOT
        timedatectl set-timezone UTC
        localectl set-locale LANG=en_US.UTF-8
      EOT
      ,
      # Replace systemd-resolved with Unbound
      <<-EOT
        systemctl mask --now systemd-resolved.service
        unlink /etc/resolv.conf && printf 'nameserver 127.0.0.1\n' > /etc/resolv.conf
        systemctl enable --now unbound.service unbound-resolvconf.service
      EOT
      ,
      # Build and install udptunnel
      <<-EOT
        mkdir /usr/local/src/udptunnel/ && cd /usr/local/src/udptunnel/
        git clone 'https://github.com/hectorm/udptunnel.git' ./
        git checkout '796e53532fbd6acc4d51849d161b4e08cc187263'
        make install-strip PREFIX=/usr/local
        udptunnel --help
      EOT
      ,
      # Setup services and timers
      <<-EOT
        systemctl enable \
          apparmor.service \
          apt-daily-upgrade.timer \
          apt-daily.timer \
          nftables.service \
          ssh.service \
          udptunnel.service \
          unattended-upgrades.service \
          wg-quick@wg0.service
        systemctl mask \
          snapd.service \
          ufw.service
      EOT
      ,
      # Delete "ubuntu" user
      <<-EOT
        if id -u ubuntu >/dev/null 2>&1; then userdel -r ubuntu; fi
      EOT
      ,
      # Create "ssh-user" group
      <<-EOT
        groupadd -r ssh-user
        usermod -aG ssh-user root
      EOT
      ,
      # Delete "root" user password
      <<-EOT
        usermod -p '*' root
      EOT
      ,
      # Cleanup
      <<-EOT
        # Remove SSH keys
        rm -rf /etc/ssh/ssh_host_*key* /root/.ssh/
        # Remove WireGuard keys
        rm -rf /etc/wireguard/*-*key
        # Remove APT cache
        find /var/lib/apt/lists/ -mindepth 1 -delete
        # Remove APT backup files
        find / -type f -regex '.+\.\(dpkg\|ucf\)-\(old\|new\|dist\)' -delete ||:
        # Remove snap directories
        for d in /root/snap/ /home/*/snap/; do rm -rf "$d"; done
        # Remove cloud-init artifacts
        cloud-init clean --logs
        # Remove systemd journal logs
        journalctl --rotate && journalctl --vacuum-time=1s
        # Empty log files
        find /var/log/ -type f -not -path '/var/log/journal/*' -exec sh -euc '> "$1"' _ '{}' ';'
        # Remove temporary files
        find /tmp/ /var/tmp/ -ignore_readdir_race -mindepth 1 -delete ||:
        # Reset machine ID
        > /etc/machine-id
      EOT
    ]
  }
}
