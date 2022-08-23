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
      <<EOF
        find /tmp/rootfs/ -type f -name .gitkeep -delete
        find /tmp/rootfs/ -type d -exec chmod 755 '{}' ';' -exec chown root:root '{}' ';'
        find /tmp/rootfs/ -type f -exec chmod 644 '{}' ';' -exec chown root:root '{}' ';'
        find /tmp/rootfs/ -type f -regex '.+/bin/.+' -exec chmod 755 '{}' ';'
        find /tmp/rootfs/ -type f -regex '.+/\(etc/wireguard\)/.+' -exec chmod 600 '{}' ';'
        find /tmp/rootfs/ -mindepth 1 -maxdepth 1 -exec cp -fla '{}' / ';'
        rm -rf /tmp/rootfs/
      EOF
      ,
      # Reload systemd manager configuration
      <<EOF
        systemctl daemon-reload
      EOF
      ,
      # Upgrade system
      <<EOF
        apt-get update
        apt-get dist-upgrade -o DPkg::Lock::Timeout=300 -y
      EOF
      ,
      # Install packages
      <<EOF
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
      EOF
      ,
      # Remove packages
      <<EOF
        apt-get purge -y \
          lxd-agent-loader \
          snapd \
          ufw
        apt-get autoremove -y
      EOF
      ,
      # Set timezone and locale
      <<EOF
        timedatectl set-timezone UTC
        localectl set-locale LANG=en_US.UTF-8
      EOF
      ,
      # Replace systemd-resolved with Unbound
      <<EOF
        systemctl mask --now systemd-resolved.service
        unlink /etc/resolv.conf && printf 'nameserver 127.0.0.1\n' > /etc/resolv.conf
        systemctl enable --now unbound.service unbound-resolvconf.service
      EOF
      ,
      # Build and install udptunnel
      <<EOF
        mkdir /usr/local/src/udptunnel/ && cd /usr/local/src/udptunnel/
        git clone 'https://github.com/hectorm/udptunnel.git' ./
        git checkout '0739600886ae05a67b6921d4154237cfdd109dd4'
        ./udptunnel-installer.sh PREFIX=/usr/local
        udptunnel --help
      EOF
      ,
      # Setup services and timers
      <<EOF
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
      EOF
      ,
      # Delete "ubuntu" user
      <<EOF
        if id -u ubuntu >/dev/null 2>&1; then userdel -r ubuntu; fi
      EOF
      ,
      # Create "ssh-user" group
      <<EOF
        groupadd -r ssh-user
        usermod -aG ssh-user root
      EOF
      ,
      # Delete "root" user password
      <<EOF
        usermod -p '*' root
      EOF
      ,
      # Cleanup
      <<EOF
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
      EOF
    ]
  }
}
