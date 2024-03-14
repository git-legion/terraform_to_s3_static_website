# Configure the AWS provider
provider "aws" {
  region = "ap-south-1" # Update with your desired region
}

# Define variable for bucket name
variable "bucket_name" {
  default = "sanjay.grrass"
}

# Define variable for website index document
variable "website_index_document" {
  type    = string
  default = "index.html"  # Set a default value if desired
}

# Create the S3 bucket
resource "aws_s3_bucket" "static_website" {
  bucket = var.bucket_name
}

# Configure public access settings to disable block all public access
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls   = false
  ignore_public_acls  = false
  block_public_policy = false
  restrict_public_buckets = false
}

# Configure website hosting using separate resource
resource "aws_s3_bucket_website_configuration" "static_website_config" {
  bucket = aws_s3_bucket.static_website.id

  # Define the index_document block
  index_document {
    suffix = var.website_index_document  # Use suffix for the index document
  }
}

# Upload the index.html file to the bucket (without ACL)
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.static_website.id
  key          = var.website_index_document
  source       = "./index.html" # Update path if your file is elsewhere
  content_type = "text/html"
}

# Define bucket policy to allow public access
resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.static_website.id
  depends_on = [aws_s3_bucket_public_access_block.public_access_block]

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "MYBUCKETPOLICY"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_website.arn}/*"
      }
    ]
  })
}

# Output the website endpoint (use recommended alternative based on AWS provider documentation)
output "website_endpoint" {
  value = aws_s3_bucket.static_website.website_endpoint
}

