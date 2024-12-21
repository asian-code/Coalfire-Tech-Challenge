terraform {
  backend "s3" {
    bucket         = "eric-coalfire-bucket"
    key            = "terraform.tfstate"
    encrypt        = true
    dynamodb_table = "coalfire"
    profile        = "eric"
    region         = "us-east-2"
  }
}
provider "aws" {
  profile = "eric"
  region  = var.region
}


# For anything related to IAM roles, policies, and S3 buckets

resource "aws_iam_role" "ec2_logs_role" {
  name = "eric-coalfire-logs-role"
  assume_role_policy = jsonencode({ # allow ec2 to assume this role
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    createdBy = "terraform"
  }
}
resource "aws_iam_policy" "log_write_policy" { # used the IAM policy generator in console to help make this policy
  name        = "eric-coalfire-setLogs-policy"
  description = "Policy to write files to images S3 bucket"
  policy = jsonencode({ # write permission to the logs bucket
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject"
        ],
        "Resource" : "${module.logs_bucket.arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_log_policy_attach" {
  role       = aws_iam_role.ec2_logs_role.name
  policy_arn = aws_iam_policy.log_write_policy.arn
}
# Create the policy, then attach the policy to the role

resource "aws_iam_role" "ec2_images_logs_role" {
  name = "eric-coalfire-Getimages-addLogs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    createdBy = "terraform"
  }
}
resource "aws_iam_policy" "s3_read_policy" { # used the IAM policy generator in console to help make this policy
  name        = "eric-coalfire-getImages-policy"
  description = "Policy to allow reading files from images S3 bucket"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "s3:Get*",
          "s3:List*"
        ],
        "Resource" : "${module.images_bucket.arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_policy_attach" {
  role       = aws_iam_role.ec2_images_logs_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}
resource "aws_iam_role_policy_attachment" "ec2_log_policy_attach2" {
  role       = aws_iam_role.ec2_images_logs_role.name
  policy_arn = aws_iam_policy.log_write_policy.arn
}
module "images_bucket" {
  source = "github.com/Coalfire-CF/terraform-aws-s3"

  name                                 = var.images_bucket_name
  enable_lifecycle_configuration_rules = true
   lifecycle_configuration_rules =[{
      id      = "memes"
      prefix="${var.image_folders[1]}/" # prefix for the memes folder
      enabled = true

      enable_glacier_transition            = true
      enable_current_object_expiration     = true
      enable_noncurrent_version_expiration = true

      abort_incomplete_multipart_upload_days     = 1
      noncurrent_version_glacier_transition_days = 90
      noncurrent_version_expiration_days         = 365
      glacier_transition_days                    = 90
      expiration_days                            = 365
  }]


  enable_kms                    = true
  enable_server_side_encryption = true
}
resource "aws_s3_object" "image_folders" { # create archive and memes "folders"
  for_each = toset(var.image_folders)
  bucket   = module.images_bucket.id
  key      = "${each.key}/"
  source   = null

  tags = {
    createdBy = "terraform"
  }
}
module "logs_bucket" {
  source = "github.com/Coalfire-CF/terraform-aws-s3"

  name                                 = var.logs_bucket_name
  enable_lifecycle_configuration_rules = true
   lifecycle_configuration_rules =[{
      id      = "active folder"
      prefix="${var.log_folders[0]}/" # prefix for the active folder
      enabled = true

      enable_glacier_transition            = true
      enable_current_object_expiration     = true
      enable_noncurrent_version_expiration = true

      abort_incomplete_multipart_upload_days     = 1
      noncurrent_version_glacier_transition_days = 90
      noncurrent_version_expiration_days         = 365
      glacier_transition_days                    = 90
      expiration_days                            = 365
  },{
      id      = "In-active folder"
      prefix="${var.log_folders[1]}/" # prefix for the INactive folder
      enabled = true

      enable_glacier_transition            = false
      enable_current_object_expiration     = true
      enable_noncurrent_version_expiration = true

      abort_incomplete_multipart_upload_days     = 1
      # noncurrent_version_glacier_transition_days = 90
      noncurrent_version_expiration_days         = 90
      # glacier_transition_days                    = 90
      expiration_days                            = 90
  }]
  enable_kms                    = true
  enable_server_side_encryption = true
}
resource "aws_s3_object" "log_folders" { # create active and inactive "folders"
  for_each = toset(var.log_folders)
  bucket   = module.logs_bucket.id
  key      = "${each.key}/"
  source   = null

  tags = {
    createdBy = "terraform"
  }
}

