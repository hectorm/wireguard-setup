# WireGuard + Unbound

[WireGuard](https://wireguard.com) and [Unbound](https://unbound.net) setup with
[Packer](https://packer.io) and [Terraform](https://terraform.io) / [OpenTofu](https://opentofu.org) ready for deployment in
[Hetzner Cloud](https://hetzner.com).

## Deployment instructions

 1. Copy `./packer/packer.auto.pkrvars.hcl.sample` file to `./packer/packer.auto.pkrvars.hcl` and
 fill it with the appropriate values.

 2. Build the server image with Packer.
 ```sh
 cd ./packer/
 packer init ./
 packer build -only=hcloud.main ./
 ```

 3. Copy `./terraform/terraform.tfvars.sample` file to `./terraform/terraform.tfvars` and fill it
 with the appropriate values.

 4. Deploy the server image with Terraform.
 ```sh
 cd ./terraform/
 terraform init
 terraform apply
 ```
