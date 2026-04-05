terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
  }
  # Збереження tfstate файлу у хмарі
  backend "s3" {
    endpoints                   = { s3 = "https://fra1.digitaloceanspaces.com" }
    region                      = "us-east-1"
    bucket                      = "mykhalchuk-tfstate"
    key                         = "task1/terraform.tfstate"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}

provider "digitalocean" {
  token             = var.do_token
  spaces_access_id  = var.spaces_access_id
  spaces_secret_key = var.spaces_secret_key
}

# VPC (Мережа)
resource "digitalocean_vpc" "mykhalchuk_vpc" {
  name     = "mykhalchuk-vpc"
  region   = "fra1"
  ip_range = "10.10.10.0/24"
}

# ВМ (Droplet)
resource "digitalocean_droplet" "mykhalchuk_node" {
  name     = "mykhalchuk-node"
  image    = "ubuntu-24-04-x64"
  region   = "fra1"
  size     = "s-2vcpu-4gb"
  vpc_uuid = digitalocean_vpc.mykhalchuk_vpc.id
}

# Фаєрвол
resource "digitalocean_firewall" "mykhalchuk_firewall" {
  name = "mykhalchuk-firewall"
  droplet_ids = [digitalocean_droplet.mykhalchuk_node.id]

  dynamic "inbound_rule" {
    for_each = ["22", "80", "443", "8000", "8001", "8002", "8003"]
    content {
      protocol         = "tcp"
      port_range       = inbound_rule.value
      source_addresses = ["0.0.0.0/0", "::/0"]
    }
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Бакет
resource "digitalocean_spaces_bucket" "mykhalchuk_bucket" {
  name   = "mykhalchuk-bucket"
  region = "fra1"
}