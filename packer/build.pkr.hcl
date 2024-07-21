build {
  sources = [
    "source.hcloud.main",
    "source.digitalocean.main",
    "source.qemu.main",
    "source.qemu.baremetal"
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
        find /tmp/rootfs/ -mindepth 1 -maxdepth 1 -exec cp -fa '{}' / ';'
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
          gettext-base \
          htop \
          linux-virtual-hwe-"$(lsb_release -rs)" \
          locales \
          nano \
          nftables \
          openresolv \
          qrencode \
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
      # Setup services and timers
      <<-EOT
        systemctl enable \
          apparmor.service \
          apt-daily-upgrade.timer \
          apt-daily.timer \
          nftables.service \
          ssh.service \
          unattended-upgrades.service \
          wg-quick@wg0.service
        systemctl mask \
          snapd.service \
          ufw.service
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
        apt-get clean; find /var/lib/apt/lists/ -mindepth 1 -delete
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
        # Clear unused disk space
        dd if=/dev/zero of=/zero bs=1M 2>/dev/null ||:; rm -f /zero
      EOT
    ]
  }
}
