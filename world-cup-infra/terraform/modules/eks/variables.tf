variable "project_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "eks_subnet_ids" {
  type = list(string)
}

variable "eks_nodes_sg_id" {
  type = string
}
