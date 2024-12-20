output "az-available" {
  value = data.aws_availability_zones.available.names
}
# output "ec2_public_ip" {
#   value = aws_instance.myVM.public_ip
# }
# output "AMI_REDHAT" {
#   value = data.aws_ami.redhat
# }
output "images_bucket_arn" {
  value = module.images_bucket.arn
}