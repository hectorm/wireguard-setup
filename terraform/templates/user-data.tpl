#cloud-config

write_files:
  - path: "/etc/wireguard/wg0.conf.d/privatekey"
    owner: "root:root"
    permissions: "0600"
    content: |
      ${wg_server_wg_privatekey}
runcmd:
  %{~ for index, pubkey in wg_server_wg_peer_publickeys ~}
  - wg-create-peer --interface wg0 --peer-number "${index}" --peer-private-key "none" --peer-public-key "${pubkey}" --quiet
  %{~ endfor ~}
  - systemctl try-restart wg-quick@wg0.service
