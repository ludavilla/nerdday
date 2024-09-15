# Configure the IBM Cloud Provider
terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "~> 1.45.0"
    }
  }
}

provider "ibm" {
  # Configure the IBM Cloud provider
  region = "us-south"
  ibmcloud_api_key = "chave_api_ibm_cloud"
}

data "ibm_is_images" "rocky" {
  visibility = "public"
  status     = "available"
}
locals {
  rocky_image = [
    for image in data.ibm_is_images.rocky.images :
    image if can(regex("^ibm-rocky-linux-8-10-minimal", image.name))
  ][0]
}
# Create a VPC
resource "ibm_is_vpc" "nerdday_vpc" {
  name = "nerdday-vpc"
}

# Create a subnet
resource "ibm_is_subnet" "nerdday_subnet" {
  name            = "nerdday-subnet"
  vpc             = ibm_is_vpc.nerdday_vpc.id
  zone            = "us-south-1"
  ipv4_cidr_block = "10.240.0.0/24"
}

# Create a security group
resource "ibm_is_security_group" "nerdday_security_group" {
  name = "nerdday-security-group"
  vpc  = ibm_is_vpc.nerdday_vpc.id
}

resource "ibm_is_security_group_rule" "nerdday_sg_rule_8088" {
  group     = ibm_is_security_group.nerdday_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 8088
    port_max = 8088
  }
}

resource "ibm_is_security_group_rule" "nerdday_sg_rule_22" {
  group     = ibm_is_security_group.nerdday_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "allow_all_outbound" {
  group     = ibm_is_security_group.nerdday_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# Create a virtual server instance
resource "ibm_is_instance" "nerdday_instance" {
  name    = "nerdday-instance"
  image   = local.rocky_image.id # Rocky Linux 8 image ID
  profile = "cx2-2x4" # 2 vCPUs, 4 GB RAM

  boot_volume {
    name = "nerdday-volume"
    size = 100  # Tamanho em GB, ajustado para 100 GB
  }

  primary_network_interface {
    subnet          = ibm_is_subnet.nerdday_subnet.id
    security_groups = [ibm_is_security_group.nerdday_security_group.id]
  }

  vpc  = ibm_is_vpc.nerdday_vpc.id
  zone = "us-south-1"
  keys = [ibm_is_ssh_key.nerdday_ssh_key.id]

}

# Create an SSH key
resource "ibm_is_ssh_key" "nerdday_ssh_key" {
  name       = "nerdday-ssh-key"
  public_key = "ssh-rsa AAAAB" # Replace with your public SSH key
}

# Create a floating IP
resource "ibm_is_floating_ip" "nerdday_floating_ip" {
  name   = "nerdday-floating-ip"
  target = ibm_is_instance.nerdday_instance.primary_network_interface[0].id
}

# Output the public IP address
output "public_ip" {
  value = {
    IP_floating = ibm_is_floating_ip.nerdday_floating_ip.address
    }
}
