variable "project_name" {
  type = string
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "eks_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "rds_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.5.0/24", "10.0.6.0/24"]
}

variable "container_port" {
  type        = number
  default     = 8080
  description = "Port app lives on & NLB forwards here"
}
