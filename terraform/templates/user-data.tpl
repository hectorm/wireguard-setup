#cloud-config

write_files:
  - path: "/etc/wireguard/wg0.conf.d/privatekey"
    owner: "root:root"
    permissions: "0600"
    content: |
      ${wg_server_wg_privatekey}
runcmd:
  %{~ for index, peer in wg_server_wg_peers ~}
  - |
    wg-create-peer \
      --interface wg0 \
      --peer-number "${index}" \
      --peer-comment "${peer.comment}" \
      --peer-private-key "none" \
      --peer-public-key "${peer.publickey}" \
      --peer-preshared-key "${peer.presharedkey}" \
      --quiet
  %{~ endfor ~}
  - systemctl try-restart wg-quick@wg0.service
