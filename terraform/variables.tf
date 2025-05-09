variable "project_tag" {
  description = "Tag variable for the Connecting The Dots S3 Web Application"
  default     = "connectingthedots-s3-web-app"
}

variable "region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "acm_cert_arn" {
  description = "ARN of the ACM certificate in us-east-1"
  type        = string
}

variable "route53_zone_id" {
  description = "The Route 53 Hosted Zone ID for the domain"
  type        = string
}
