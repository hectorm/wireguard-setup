#cloud-config

write_files:
  - path: "/etc/wireguard/wg0-privatekey"
    owner: "root:root"
    permissions: "0600"
    content: |
      ${wg_server_own_privatekey}
  - path: "/etc/wireguard/wg0-peers.conf"
    owner: "root:root"
    permissions: "0644"
    content: |
      %{~ for index, pubkey in wg_server_peer_publickeys ~}
      [Peer]
      PublicKey = ${pubkey}
      AllowedIPs = 10.10.10.${index+2}/32, fd10:10:10::${index+2}/128
      %{~ endfor ~}
