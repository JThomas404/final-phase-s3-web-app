provider "aws" {
  region = var.region
}

resource "random_id" "ctdc-random-number" {
  byte_length = 8
}

resource "aws_s3_bucket" "ctdc-s3-bucket" {
  bucket = "connectingthedots-${random_id.ctdc-random-number.hex}"

  tags = {
    Name = var.project_tag
  }
}

resource "aws_s3_bucket_website_configuration" "ctdc_site_config" {
  bucket = aws_s3_bucket.ctdc-s3-bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

data "aws_iam_policy_document" "public_read" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.ctdc-s3-bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    effect = "Allow"
  }
}

resource "aws_s3_bucket_public_access_block" "disable_block_public" {
  bucket = aws_s3_bucket.ctdc-s3-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_access" {
  bucket = aws_s3_bucket.ctdc-s3-bucket.id
  policy = data.aws_iam_policy_document.public_read.json

  depends_on = [aws_s3_bucket_public_access_block.disable_block_public]
}

resource "aws_dynamodb_table" "ctdc-dynamodb" {
  name         = "ConnectingTheDots"
  hash_key     = "email"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "email"
    type = "S"
  }

  tags = {
    Name = var.project_tag
  }
}

output "s3_static_site_url" {
  value       = "http://${aws_s3_bucket.ctdc-s3-bucket.bucket}.s3-website-${var.region}.amazonaws.com"
  description = "The public URL of the static website hosted on S3"
}
