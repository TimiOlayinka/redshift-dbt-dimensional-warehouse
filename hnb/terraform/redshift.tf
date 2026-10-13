resource "aws_redshiftserverless_namespace" "dwh" {
  namespace_name      = "${var.project_name}-${var.environment}-ns"
  db_name             = var.redshift_database_name
  admin_username      = var.redshift_admin_username
  admin_user_password = var.redshift_admin_password
  iam_roles           = [aws_iam_role.redshift_s3_access.arn]
  default_iam_role_arn = aws_iam_role.redshift_s3_access.arn

  log_exports = [
    "userlog",
    "connectionlog",
    "useractivitylog"
  ]
}

resource "aws_redshiftserverless_workgroup" "dwh" {
  namespace_name      = aws_redshiftserverless_namespace.dwh.namespace_name
  workgroup_name      = "${var.project_name}-${var.environment}-wg"
  base_capacity       = var.redshift_base_rpu
  max_capacity        = 32
  publicly_accessible = false

  config_parameter {
    parameter_key   = "enable_user_activity_logging"
    parameter_value = "true"
  }

  config_parameter {
    parameter_key   = "max_query_execution_time"
    parameter_value = "1800"
  }
}

# FinOps Guardrail: Cap daily RPU-hour consumption to prevent runaway analytical queries
resource "aws_redshiftserverless_usage_limit" "daily_rpu_cap" {
  resource_arn  = aws_redshiftserverless_workgroup.dwh.arn
  usage_type    = "serverless-compute"
  amount        = var.redshift_max_rpu_hours_per_day
  period        = "daily"
  breach_action = "deactivate"
}
