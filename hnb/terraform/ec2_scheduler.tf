# FinOps EC2 Start/Stop Scheduler via EventBridge Scheduler
# Starts the Airflow EC2 host at 00:45 UTC (before 01:00 UTC ingestion) and stops it at 04:00 UTC,
# cutting EC2 orchestration compute spend by >80%.

resource "aws_iam_role" "ec2_scheduler_role" {
  name = "${var.project_name}-${var.environment}-ec2-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "scheduler.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_start_stop_policy" {
  name = "${var.project_name}-${var.environment}-ec2-start-stop"
  role = aws_iam_role.ec2_scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = aws_instance.airflow_host.arn
      }
    ]
  })
}

resource "aws_scheduler_schedule" "start_airflow_ec2" {
  name                         = "${var.project_name}-${var.environment}-start-airflow"
  description                  = "Boot Airflow EC2 host daily at 00:45 UTC ahead of the 01:00 UTC ELT batch window"
  schedule_expression          = "cron(45 0 * * ? *)"
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.ec2_scheduler_role.arn

    input = jsonencode({
      InstanceIds = [aws_instance.airflow_host.id]
    })
  }
}

resource "aws_scheduler_schedule" "stop_airflow_ec2" {
  name                         = "${var.project_name}-${var.environment}-stop-airflow"
  description                  = "Stop Airflow EC2 host daily at 04:00 UTC after ADL marts and dbt tests complete"
  schedule_expression          = "cron(0 4 * * ? *)"
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.ec2_scheduler_role.arn

    input = jsonencode({
      InstanceIds = [aws_instance.airflow_host.id]
    })
  }
}
