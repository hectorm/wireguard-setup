# WireGuard + Unbound

[WireGuard](https://www.wireguard.com) and [Unbound](https://unbound.net) setup with
[Packer](https://www.packer.io) and [Terraform](https://www.terraform.io) ready for deployment in
[Hetzner Cloud](https://www.hetzner.com).

## Deployment instructions

 1. Copy `./packer/packer.auto.pkrvars.hcl.sample` file to `./packer/packer.auto.pkrvars.hcl` and
 fill it with the appropriate values.

 2. Build the server image with Packer.
 ```sh
 cd ./packer/
 packer build ./
 ```

 3. Copy `./terraform/terraform.tfvars.sample` file to `./terraform/terraform.tfvars` and fill it
 with the appropriate values.

 4. Deploy the server image with Terraform.
 ```sh
 cd ./terraform/
 terraform init
 terraform apply
 ```
