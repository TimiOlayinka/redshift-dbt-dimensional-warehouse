variable "aws_region" {
  description = "Primary AWS region for the H&B Lakehouse and Redshift Serverless platform (London)."
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Canonical prefix for all provisioned AWS resources."
  type        = string
  default     = "hnb-cx-dwh"
}

variable "environment" {
  description = "Deployment environment tier (dev, staging, prod)."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "s3_data_lake_bucket_name" {
  description = "Globally unique S3 bucket name for the H&B Raw Data Lake."
  type        = string
  default     = "hnb-data-lake"
}

variable "redshift_database_name" {
  description = "Primary database created inside the Redshift Serverless namespace."
  type        = string
  default     = "hnb_dwh_prod"
}

variable "redshift_admin_username" {
  description = "Master administrator username for Amazon Redshift Serverless."
  type        = string
  default     = "hnb_dwh_admin"
}

variable "redshift_admin_password" {
  description = "Master administrator password for Amazon Redshift Serverless (injected via TF_VAR or Secrets Manager)."
  type        = string
  sensitive   = true
  default     = null
}

variable "redshift_base_rpu" {
  description = "Base Redshift Processing Units (RPUs) for Redshift Serverless workgroup."
  type        = number
  default     = 8
}

variable "redshift_max_rpu_hours_per_day" {
  description = "Daily FinOps usage limit (RPU-hours) before throttling/alerting."
  type        = number
  default     = 64
}

variable "airflow_instance_type" {
  description = "EC2 instance type hosting the containerized Apache Airflow & dbt scheduler."
  type        = string
  default     = "t3.large"
}

variable "airflow_allowed_cidr_blocks" {
  description = "List of corporate VPN / CIDR blocks permitted to access the Airflow UI (port 8080)."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}
