# ${WG_PEER_COMMENT}
[Interface]
PrivateKey = ${WG_PEER_PRIVATE_KEY}
Address = 10.100.${WG_PEER_IPV4_SUFFIX}/32, fd10:100::${WG_PEER_IPV6_SUFFIX}/128
DNS = 10.100.0.1, fd10:100::1

[Peer]
PublicKey = ${WG_OWN_PUBLIC_KEY}
PresharedKey = ${WG_PEER_PRESHARED_KEY}
AllowedIPs = 0.0.0.0/0, ::0/0
Endpoint = XXX.XXX.XXX.XXX:51820
