output "s3_data_lake_bucket_arn" {
  description = "ARN of the H&B S3 Data Lake bucket."
  value       = aws_s3_bucket.data_lake.arn
}

output "s3_data_lake_bucket_name" {
  description = "Bucket name of the H&B S3 Data Lake."
  value       = aws_s3_bucket.data_lake.id
}

output "redshift_serverless_workgroup_endpoint" {
  description = "JDBC/ODBC connection endpoint for the Redshift Serverless workgroup."
  value       = aws_redshiftserverless_workgroup.dwh.endpoint
}

output "redshift_serverless_namespace_arn" {
  description = "ARN of the Redshift Serverless namespace."
  value       = aws_redshiftserverless_namespace.dwh.arn
}

output "redshift_s3_copy_role_arn" {
  description = "IAM Role ARN used by Redshift COPY commands to ingest JSONL.GZ files from S3."
  value       = aws_iam_role.redshift_s3_access.arn
}

output "lambda_function_arns" {
  description = "Map of deployed CX and E-Commerce ingestion Lambda function names to their ARNs."
  value       = { for k, v in aws_lambda_function.ingestion_generators : k => v.arn }
}

output "airflow_ec2_instance_id" {
  description = "Instance ID of the managed Apache Airflow & dbt Core EC2 host."
  value       = aws_instance.airflow_host.id
}
