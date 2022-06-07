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

output "instance_count" {
  description = "Number of instances"
  value = data.ibm_is_instances.example
}
