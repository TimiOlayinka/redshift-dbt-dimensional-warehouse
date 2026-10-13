locals {
  lambda_generators = {
    cx_nps_postship = {
      description = "Generates simulated post-delivery SMG NPS survey batches into S3"
      memory_size = 256
      timeout     = 60
    }
    cx_nps_visitview = {
      description = "Generates simulated digital web/app SMG VisitView NPS batches into S3"
      memory_size = 256
      timeout     = 60
    }
    cx_customer_support = {
      description = "Generates simulated Zendesk Customer Care support ticket & CSAT batches into S3"
      memory_size = 256
      timeout     = 60
    }
    ecommerce_basket_items = {
      description = "Generates simulated E-Commerce shopping basket line items into S3"
      memory_size = 512
      timeout     = 90
    }
    ecommerce_basket_payments = {
      description = "Generates simulated E-Commerce checkout payment settlements into S3"
      memory_size = 256
      timeout     = 60
    }
  }
}

resource "aws_lambda_function" "ingestion_generators" {
  for_each = local.lambda_generators

  function_name    = each.key
  description      = each.value.description
  role             = aws_iam_role.lambda_ingestion_exec.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.11"
  architectures    = ["arm64"] # AWS Graviton2 for 20% better price-performance
  filename         = "${path.module}/../dist/${each.key}.zip"
  source_code_hash = fileexists("${path.module}/../dist/${each.key}.zip") ? filebase64sha256("${path.module}/../dist/${each.key}.zip") : null
  memory_size      = each.value.memory_size
  timeout          = each.value.timeout

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.data_lake.id
      DRY_RUN   = "false"
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = local.lambda_generators

  name              = "/aws/lambda/${each.key}"
  retention_in_days = 14
}
