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

locals {

  # 名前が"name"と一致するインスタンスを抽出する。
  name = "mytest-vsi1"
  target = [for i in data.ibm_is_instances.example.instances :
            i if i.name == local.name]

  # 既存のインスタンスが存在するか確認する。
  is_target = length(local.target) >= 1 ? true : false

  # 既存インスタンスがあれば、"status"を取得する。無ければ、"null"を設定する。
  # - "name"と合致するインスタンスは、1つしかない前提
  status_current = local.is_target ? local.target.0.status : null
  instance_id = local.is_target ? local.target.0.id : null

  # 既存インスタンスの"status"が"running"であれば"off"に変える。
  #                           "running"で無ければ"on"にする。
  # 既存インスタンスがない場合はDefault値にする。
  tag_default = {
    tags = ["on"]
  }

  tag_on = {
    tags = ["on"]
  }

  tag_off = {
    tags = ["off"]
  }

  # 既存インスタンスの状態が"running"の場合、かつ、
  #   - 現在のタグが"on"の場合: "tag_next"を"off"にする。
  #   - 現在のタグが"on"でない場合: "tag_next"を"on"にする。
  # 既存インスタンスの状態が"runnning"ではない場合、
  #   - "tag_next"は、空にする。
  tag_next = local.is_target == true ? local.status_current == "running" ? local.tag_off.tags : local.tag_on.tags : []
 
  # tag_result = concat(local.tag_next, local.tag_default.tags)
}

resource null_resource "preset" {
  provisioner "local-exec" {
    on_failure = fail
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      echo hoge
      echo ${local.name}
      if [ ${local.status_current} ==  "running" ]
      then
        echo ${local.instance_id}
      fi
      ibmcloud target -r jp-tok
      ibmcloud is vpcs
      ibmcloud is instance ${local.instance_id}
    EOT
  }
  triggers = {
    always_run = "${timestamp()}"
  }
  depends_on = [ibm_is_instance.vsi1]
}

resource ibm_is_instance "vsi1" {

  name = "${local.BASENAME}-vsi1"
  resource_group = "${data.ibm_resource_group.group.id}"
  vpc = ibm_is_vpc.vpc.id
  zone = "${local.ZONE}"
  keys = [data.ibm_is_ssh_key.ssh_key_id.id]
  image = data.ibm_is_image.ubuntu.id
  profile = "bx2-2x8"
  tags = local.tag_default.tags

  primary_network_interface {
    subnet = ibm_is_subnet.subnet1.id
    security_groups = [ibm_is_security_group.sg1.id]
  }
}

data "ibm_is_instances" "example" {
}

output vpc_id {
  value = ibm_is_vpc.vpc.id
}

output "instance_count" {
#  description = "Number of instances"
  value = local.tag_next
#  value = data.ibm_is_instances.example.instances.0.id
}

output "instances" {
  value = data.ibm_is_instances.example
}
