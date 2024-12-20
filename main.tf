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
data "aws_availability_zones" "available" {
  state = "available"
}
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    createdBy = "terraform"
    Name      = "main-vpc"
  }
}

# create the public subnets
resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = data.aws_availability_zones.available.names[each.key == "subnet1" ? 0 : 1]

  tags = {
    createdBy = "terraform"
    Name      = "public-${each.key}"
  }
}
# create the private subnets
resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[each.key == "subnet3" ? 0 : 1]

  tags = {
    createdBy = "terraform"
    Name      = "private-${each.key}"
  }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    createdBy = "terraform"
    Name      = "main-tf-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    createdBy = "terraform"
    Name      = "public-rt"
  }
}

resource "aws_route_table_association" "public_association" { # loop through each public subnet and assign the route table
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table" "private" { # local route is added by default
  vpc_id = aws_vpc.main.id

  tags = {
    createdBy = "terraform"
    Name      = "private-rt"
  }
}

resource "aws_route_table_association" "private_association" { # loop through each private subnet and assign the route table
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
data "aws_ami" "redhat" {
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-9.0.0_HVM*x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  # prob doesnt have the ec2 connect agent installed
  owners = ["309956199498"] # Red hat i think
}
resource "aws_security_group" "private_sg" {
  name        = "private-sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.main.id
  tags = {
    createdBy = "terraform"
    Name      = "private_sg"
  }
}
resource "aws_vpc_security_group_ingress_rule" "private_allow_https_alb" {
  security_group_id            = aws_security_group.private_sg.id
  referenced_security_group_id = aws_security_group.lb_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}
resource "aws_security_group" "lb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP traffic and outbound HTTPS to private SG"
  vpc_id      = aws_vpc.main.id
  tags = {
    createdBy = "terraform"
    Name      = "alb_sg"
  }
}
# resource "aws_vpc_security_group_ingress_rule" "allow_https_in_lb" {
#   security_group_id = aws_security_group.lb_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }
resource "aws_vpc_security_group_ingress_rule" "allow_http_in_lb" {
  security_group_id = aws_security_group.lb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_egress_rule" "allow_https_out_lb" {
  security_group_id            = aws_security_group.lb_sg.id
  referenced_security_group_id = aws_security_group.private_sg.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}
# copied from console key editor in console
resource "aws_kms_key" "ebs" {
  description              = "key for EBS encryption"
  deletion_window_in_days  = 7
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  policy = jsonencode({
    "Id" : "key-consolepolicy-3",
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::211125604618:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow access for Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::211125604618:user/EricN"
        },
        "Action" : [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion",
          "kms:RotateKeyOnDemand"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow use of the key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::211125604618:user/EricN"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow attachment of persistent resources",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::211125604618:user/EricN"
        },
        "Action" : [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        "Resource" : "*",
        "Condition" : {
          "Bool" : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      }
    ]
  })
  tags = {
    createdBy = "terraform"
  Alias = "ebs-kms-key" }
}
resource "aws_kms_alias" "ebs" {
  name          = "alias/ebs-kms-key"
  target_key_id = aws_kms_key.ebs.key_id
}
module "myVM" {
  source = "github.com/Coalfire-CF/terraform-aws-ec2"

  name = "MyVM"

  ami               = data.aws_ami.redhat.id
  ec2_instance_type = var.ec2_type
  instance_count    = 1

  vpc_id              = aws_vpc.main.id
  subnet_ids          = [aws_subnet.public["subnet2"].id]
  associate_public_ip = true

  ec2_key_pair    = var.ec2_key_name
  ebs_kms_key_arn = aws_kms_key.ebs.arn
  ebs_optimized   = false
  # Storage
  root_volume_size = 20

  # Security Group Rules
  ingress_rules = {
    "ssh" = {
      ip_protocol = "tcp"
      from_port   = "22"
      to_port     = "22"
      cidr_ipv4   = "0.0.0.0/0"
      description = "SSH"
    }
    # "http" = { # to test the user data script
    #   ip_protocol = "tcp"
    #   from_port   = "80"
    #   to_port     = "80"
    #   cidr_ipv4   = "0.0.0.0/0"
    #   description = "Allow HTTP"
    # }

  }

  egress_rules = {
    "allow_all_egress" = {
      ip_protocol = "-1"
      # from_port   = "0" # commented out to prevent errors since all protocols are allowed
      # to_port     = "0"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all egress"
    }
  }
  user_data = base64encode(<<-EOF
                  #!/bin/bash
                  sudo dnf update -y
                  sudo dnf install httpd -y
                  echo "<html><head><title>2nd Round</title></head><body><h1>Wooooohooo 2nd round @ Coalfire!!!</h1></body></html>" > /var/www/html/index.html
                  sudo systemctl start httpd
                  sudo systemctl enable httpd
                  EOF
  )
  # Tagging
  global_tags = { createdBy = "terraform" }
}
#region ec2 manual way
# resource "aws_security_group" "public_sg" {
#   name        = "public-sg"
#   description = "allow ssh and http traffic"
#   vpc_id      = aws_vpc.main.id
#   tags = {
#     createdBy = "terraform"

#     Name = "public_sg"
#   }
# }
# resource "aws_vpc_security_group_ingress_rule" "public_allow_ssh_ipv4" {
#   security_group_id = aws_security_group.public_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 22
#   ip_protocol       = "tcp"
#   to_port           = 22
# }
# resource "aws_vpc_security_group_ingress_rule" "public_allow_http_ipv4" {
#   security_group_id = aws_security_group.public_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 80
#   ip_protocol       = "tcp"
#   to_port           = 80
# }
# resource "aws_instance" "myVM" {
#   #   1 EC2 instance running Red Hat Linux in subnet sub2 
#   # • 20 GB storage 
#   # • t2.micro
#   ami               = data.aws_ami.redhat.id
#   availability_zone = data.aws_availability_zones.available.names[1]
#   instance_type     = var.ec2_type
#   subnet_id         = aws_subnet.public["subnet2"].id
#   security_groups   = [aws_security_group.public_sg.id]

#   tags = {
#     createdBy = "terraform"
#     Name      = "myVM"
#   }
# }
# resource "aws_ebs_volume" "myVM_storage" {
#   availability_zone = data.aws_availability_zones.available.names[1] # 2nd AZ to match the ec2 
#   size              = 20
#   tags = {
#     createdBy = "terraform"
#     Name      = "myVM_20gb_volume"
#   }
# }
# resource "aws_volume_attachment" "myVM_storage_attachment" {
#   device_name = "/dev/sda2"
#   volume_id   = aws_ebs_volume.myVM_storage.id
#   instance_id = aws_instance.myVM.id
# }
#endregion

resource "aws_autoscaling_group" "asg" {
  # Notes: placement_group are used to control the physical placement of instances in the underlying hardware
  # launch configuration are replaced with Launch Templates
  # vpc_zone_identifier Specifies a list of subnet IDs in which to launch the instances for the Auto Scaling Group.
  name             = "dualAZ-asg"
  min_size         = 2
  max_size         = 6
  desired_capacity = 3
  launch_template {
    id      = aws_launch_template.launch.id
    version = "$Latest"
  }
  # availability_zones = [data.aws_availability_zones.available.names[0],data.aws_availability_zones.available.names[1]]
  vpc_zone_identifier = [for subnet in aws_subnet.private : subnet.id] # Include all private subnet IDs

}
resource "aws_launch_template" "launch" {
  name_prefix            = "asg-launch-template-"
  image_id               = data.aws_ami.redhat.id
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
    }
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.asg_profile.name
  }
  # needs to be base64 encoded
  user_data = base64encode(<<-EOF
                  #!/bin/bash
                  sudo dnf update -y
                  sudo dnf install httpd -y
                  sudo systemctl start httpd
                  sudo systemctl enable httpd
                  echo "<html><head><title>2nd Round</title></head><body><h1>Wooooohooo 2nd round @ Coalfire!!!</h1></body></html>" > /var/www/html/index.html
                  EOF
  )

}

resource "aws_iam_instance_profile" "asg_profile" {
  name = "asg_profile"
  role = aws_iam_role.ec2_images_role.name
}
resource "aws_iam_role" "ec2_logs_role" {
  name = "eric-coalfire-logs-role"
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

resource "aws_iam_role" "ec2_images_role" {
  name = "eric-coalfire-images-role"
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
  role       = aws_iam_role.ec2_images_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
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
resource "aws_lb_target_group" "asg_tg" {
  name     = "asg-tg"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.main.id
}
resource "aws_autoscaling_attachment" "albTargetGroup_to_asg" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = aws_lb_target_group.asg_tg.arn
}
resource "aws_lb" "myalb" {
  name               = "alb-to-asg"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for subnet in aws_subnet.private : subnet.id] # Include all private subnet IDs (sub3 and sub4)
}
resource "aws_lb_listener" "myalb_listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg_tg.arn
  }
}
