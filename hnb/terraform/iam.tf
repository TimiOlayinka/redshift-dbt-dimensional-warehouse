# 1. IAM Role for Redshift Serverless COPY from S3 Data Lake
resource "aws_iam_role" "redshift_s3_access" {
  name = "${var.project_name}-${var.environment}-redshift-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "redshift.amazonaws.com",
            "redshift-serverless.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "redshift_s3_read_only" {
  name = "${var.project_name}-${var.environment}-redshift-s3-read"
  role = aws_iam_role.redshift_s3_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.data_lake.arn,
          "${aws_s3_bucket.data_lake.arn}/hnb/*"
        ]
      }
    ]
  })
}

# 2. IAM Role for Synthetic Data Generator Lambda Functions
resource "aws_iam_role" "lambda_ingestion_exec" {
  name = "${var.project_name}-${var.environment}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_s3_and_logs" {
  name = "${var.project_name}-${var.environment}-lambda-s3-write"
  role = aws_iam_role.lambda_ingestion_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:AbortMultipartUpload"
        ]
        Resource = "${aws_s3_bucket.data_lake.arn}/hnb/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

# 3. IAM Role & Instance Profile for Airflow EC2 Orchestrator
resource "aws_iam_role" "airflow_ec2_role" {
  name = "${var.project_name}-${var.environment}-airflow-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "airflow_orchestrator_permissions" {
  name = "${var.project_name}-${var.environment}-airflow-orchestrator-policy"
  role = aws_iam_role.airflow_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeIngestionLambdas"
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [
          for fn in aws_lambda_function.ingestion_generators : fn.arn
        ]
      },
      {
        Sid    = "ExecuteRedshiftDataApi"
        Effect = "Allow"
        Action = [
          "redshift-data:ExecuteStatement",
          "redshift-data:DescribeStatement",
          "redshift-data:GetStatementResult",
          "redshift-serverless:GetCredentials"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "airflow_ec2_profile" {
  name = "${var.project_name}-${var.environment}-airflow-instance-profile"
  role = aws_iam_role.airflow_ec2_role.name
}
