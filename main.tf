provider "ibm" {
  region = "jp-tok"
}

resource ibm_is_vpc "vpc" {
  name = "myvpc"
}

