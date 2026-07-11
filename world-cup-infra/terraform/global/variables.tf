variable "project_name" {
  type    = string
  default = "world-cup"
}

variable "football_api_key" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Set via TF_VAR_football_api_key or terraform.tfvars"
}

variable "football_api_url" {
  type    = string
  default = "https://api.football-data.org/v4"
}
