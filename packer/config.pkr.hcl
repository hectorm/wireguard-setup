packer {
  required_plugins {
    hcloud = {
      version = ">= 1.0.4"
      source  = "github.com/hashicorp/hcloud"
    }
    digitalocean = {
      version = ">= 1.0.6"
      source  = "github.com/hashicorp/digitalocean"
    }
  }
}
