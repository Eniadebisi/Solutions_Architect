resource "aws_secretsmanager_secret" "football_api" {
  name = "${var.project_name}/football-api"

  tags = {
    Project = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "football_api" {
  secret_id = aws_secretsmanager_secret.football_api.id
  secret_string = jsonencode({
    FOOTBALL_API_KEY = var.football_api_key
    FOOTBALL_API_URL = var.football_api_url
  })
}
