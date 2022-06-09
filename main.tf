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
  count = 0
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


output vpc_id {
  value = ibm_is_vpc.vpc.id
}

data "ibm_is_instances" "example" {
}

locals {
  #xyz = length(data.ibm_is_instances.example.instances) >= 1 ? true : false
  #abc = local.xyz ? data.ibm_is_instances.example.instances.0.id : null
  #mode_default = "hoge"
  #mode = local.xyz == true ? local.abc == "on" ? "off" : "on" : local.mode_default

  # 名前が"name"と一致するインスタンスを抽出する。
  name = "mytest-vsi1"
  target = [for i in data.ibm_is_instances.example.instances :
            i if i.name == local.name]

  # 既存のインスタンスが存在するか確認する。
  is_target = length(local.target) >= 1 ? true : false

  # 既存インスタンスがあれば、statusを取得する。無ければ、"null"を設定する。
  # - "name"と合致するインスタンスは、1つしかない前提
  status = local.is_target ? local.target.0.status : null

  # 既存インスタンスの状態が"running"であれば止める。"running"で無ければ起動する。既存インスタンスがない場合は起動する。
  # 既存インスタンスが存在しない場合の挙動が定まらないので、"is_target"が"false"の場合は、"action_default"を設定している。
  tag_cf1 = {
    tags = "cf1"
  }

  tag_cf2 = {
    tags = "cf2"
  }

  tag_default = {
    tags = "initial"
  }

  tag_next = local.is_target == true ? local.status == "running" ? tag_cf1 : tag_cf2 : local.tag_default
}

output "instance_count" {
#  description = "Number of instances"
#  value = local.mode
  value = local.tag_next
#  value = data.ibm_is_instances.example.instances.0.id
}

output "instances" {
  value = data.ibm_is_instances.example
}
