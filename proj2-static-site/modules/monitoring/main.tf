resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-alarms"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# CloudWatch Alarms 

resource "aws_cloudwatch_metric_alarm" "public_cpu_high" {
  alarm_name          = "${var.project_name}-public-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU above 80% for 10 minutes on public EC2"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]

  dimensions = {
    InstanceId = var.public_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "public_status_check" {
  alarm_name          = "${var.project_name}-public-ec2-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "EC2 status check failed"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    InstanceId = var.public_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "private_cpu_high" {
  alarm_name          = "${var.project_name}-private-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU above 80% on private EC2"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    InstanceId = var.private_instance_id
  }
}

# CloudWatch Dashboard 

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title       = "EC2 CPU Utilization"
          view        = "timeSeries"
          region      = var.aws_region
          period      = 300
          stat        = "Average"
          annotations = { horizontal = [] }
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.public_instance_id],
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.private_instance_id]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title       = "EC2 Network In/Out"
          view        = "timeSeries"
          region      = var.aws_region
          period      = 300
          stat        = "Average"
          annotations = { horizontal = [] }
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", var.public_instance_id],
            ["AWS/EC2", "NetworkOut", "InstanceId", var.public_instance_id]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title       = "EC2 Status Checks"
          view        = "timeSeries"
          region      = var.aws_region
          period      = 60
          stat        = "Maximum"
          annotations = { horizontal = [] }
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", var.public_instance_id],
            ["AWS/EC2", "StatusCheckFailed_Instance", "InstanceId", var.public_instance_id],
            ["AWS/EC2", "StatusCheckFailed_System", "InstanceId", var.public_instance_id]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title       = "S3 Bucket Size"
          view        = "timeSeries"
          region      = var.aws_region
          period      = 86400
          stat        = "Average"
          annotations = { horizontal = [] }
          metrics = [
            ["AWS/S3", "BucketSizeBytes", "BucketName", var.s3_bucket_name, "StorageType", "StandardStorage"]
          ]
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 12
        width  = 24
        height = 3
        properties = {
          title = "Alarm Status"
          alarms = [
            aws_cloudwatch_metric_alarm.public_cpu_high.arn,
            aws_cloudwatch_metric_alarm.public_status_check.arn,
            aws_cloudwatch_metric_alarm.private_cpu_high.arn
          ]
        }
      }
    ]
  })
}
