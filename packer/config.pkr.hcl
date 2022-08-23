packer {
  required_plugins {
    hcloud = {
      version = ">= 1.0.5"
      source  = "github.com/hashicorp/hcloud"
    }
    digitalocean = {
      version = ">= 1.0.8"
      source  = "github.com/digitalocean/digitalocean"
    }
    oracle = {
      version = ">= 1.0.2"
      source  = "github.com/hashicorp/oracle"
    }
  }
}
