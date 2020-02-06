# WireGuard + Unbound

[WireGuard](https://www.wireguard.com) and [Unbound](https://unbound.net) setup with
[Packer](https://www.packer.io) and [Terraform](https://www.terraform.io) ready for deployment in
[Hetzner Cloud](https://www.hetzner.com).

## Deployment instructions

 1. Build the server image with Packer.
 ```sh
 cd ./packer/
 export HCLOUD_TOKEN=XXXX
 packer build ./
 ```

 2. Deploy the server image with Terraform.
 ```sh
 cd ./terraform/
 terraform init
 terraform apply
 ```
