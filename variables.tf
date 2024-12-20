variable "region" {
  description = "the region where resources will be created in"
  default     = "us-east-2"
}
variable "vpc_cidr" {
  description = "the cidr of the main vpc"
  default     = "10.1.0.0/16"
}
variable "ec2_type" {
  default = "t2.micro"
}
variable "private_subnets" {
  description = "map of private subnets with cidr blocks"
  type        = map(string)
  default     = {
    subnet3 = "10.1.2.0/24"
    subnet4 = "10.1.3.0/24"
  }
}
variable "public_subnets" {
  description = "map of public subnets with cidr blocks"
  type        = map(string)
  default     = {
    subnet1 = "10.1.0.0/24"
    subnet2 = "10.1.1.0/24"
  }
}
variable "ec2_key_name" {
  description = "key pair name used to connect to ec2"
  default = "hehe"
}
variable "images_bucket_name" {
  description = "name of the s3 bucket to store images"
  default     = "eric-coalfire-images"
  
}
variable "logs_bucket_name" {
  description = "name of the s3 bucket to store logs"
  default     = "eric-coalfire-logs"
  
}
variable "image_folders" {
  default = ["archive", "memes"]
}
variable "log_folders" {
  default = ["Active folder", "Inactive folder"]
}