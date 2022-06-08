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
  ZONE = "jp-tok"
}

resource ibm_is_vpc "vpc" {
  name = "${local.BASENAME}-vpc"
}

resource ibm_is_security_group "sg1" {
  name = "${local.BASENAME}-sg1"
  vpc = ibm_is_vpc.vpc.id
}

#data "ibm_is_instances" "example" {
#}

#locals {
#  xyz = length(data.ibm_is_instances.example.instances) >= 1 ? true : false
#  abc = local.xyz ? data.ibm_is_instances.example.instances.0.id : "hoge"
#}

#output "instance_count" {
  #local.FLAG = length(data.ibm_is_instances.example.instances) >= 1 ? true : false
#  description = "Number of instances"
#  value = local.abc
#  value = data.ibm_is_instances.example.instances.0.id
#}
