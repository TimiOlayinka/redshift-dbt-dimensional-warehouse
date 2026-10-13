resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.s3_data_lake_bucket_name}-${var.environment}"
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# FinOps Lifecycle Policy: Intelligent Tiering -> Glacier Instant Retrieval -> Expire noncurrent versions
resource "aws_s3_bucket_lifecycle_configuration" "data_lake_finops" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id     = "vitality-raw-history-tiering"
    status = "Enabled"

    filter {
      prefix = "vitality/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
