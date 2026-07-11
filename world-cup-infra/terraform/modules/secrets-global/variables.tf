variable "project_name" {
  type = string
}

variable "football_api_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "football_api_url" {
  type    = string
  default = "https://api.football-data.org/v4"
}
