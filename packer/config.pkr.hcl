packer {
  required_plugins {
    hcloud = {
      version = ">= 1.0.3"
      source  = "github.com/hashicorp/hcloud"
    }
    digitalocean = {
      version = ">= 1.0.5"
      source  = "github.com/hashicorp/digitalocean"
    }
  }
}
