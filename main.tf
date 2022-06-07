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

resource ibm_is_vpc "vpc" {
  name = "myvpc"
}

data "ibm_is_instances" "example" {
}

locals {
 FLAG = false
}

output "instance_count" {
  #local.FLAG = length(data.ibm_is_instances.example.instances) >= 1 ? true : false
  local.FLAG = data.ibm_is_instances.example
  description = "Number of instances"
  value = local.FLAG
}
