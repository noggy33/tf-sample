terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "~> 1.12.0"
    }
  }
}

provider "ibm" {
  region = "jp-tok"
}

locals {
  BASENAME = "mytest"
  ZONE = "jp-tok-2"
}

resource ibm_is_vpc "vpc" {
  name = "${local.BASENAME}-vpc"
}

resource ibm_is_security_group "sg1" {
  name = "${local.BASENAME}-sg1"
  vpc = ibm_is_vpc.vpc.id
}

resource "ibm_is_security_group_rule" "ingress_ssh_all" {
  group = ibm_is_security_group.sg1.id
  direction = "inbound"
  remote = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource ibm_is_subnet "subnet1" {
  name = "${local.BASENAME}-subnet1"
  vpc = ibm_is_vpc.vpc.id
  zone = "${local.ZONE}"
  total_ipv4_address_count = 256
}

data ibm_is_image "ubuntu" {
  name = "ibm-ubuntu-22-04-minimal-amd64-1"
}

data ibm_is_ssh_key "ssh_key_id" {
 name = "myssh"
}

data ibm_resource_group "group" {
  name = "Default"
}

resource ibm_is_instance "vsi1" {
  name = "${local.BASENAME}-vsi1"
  resource_group = "${data.ibm_resource_group.group.id}"
  vpc = ibm_is_vpc.vpc.id
  zone = "${local.ZONE}"
  keys = [data.ibm_is_ssh_key.ssh_key_id.id]
  image = data.ibm_is_image.ubuntu.id
  profile = "bx2-2x8"

  primary_network_interface {
    subnet = ibm_is_subnet.subnet1.id
    security_groups = [ibm_is_security_group.sg1.id]
  }
}

resource ibm_is_floating_ip "fip1" {
  name = "${local.BASENAME}-fip1"
  target = ibm_is_instance.vsi1.primary_network_interface.0.id
}

output sshcommand {
  value = "ssh root@${ibm_is_floating_ip.fip1.address}"
}

output vpc_id {
  value = ibm_is_vpc.vpc.id
}

data "ibm_is_instances" "example" {
}

locals {
  xyz = length(data.ibm_is_instances.example.instances) >= 1 ? true : false
  abc = local.xyz ? data.ibm_is_instances.example.instances.0.id : null
  mode_default = "hoge"
  mode = local.abc != null ? local.abc == "on" ? "off" : "on" : local.mode_default
}

output "instance_count" {
#  description = "Number of instances"
  value = local.mode
#  value = data.ibm_is_instances.example.instances.0.id
}
