output "flow_log_group_name" {
  value = aws_cloudwatch_log_group.flow_logs.name
}

output "flow_log_id" {
  value = aws_flow_log.main.id
}
