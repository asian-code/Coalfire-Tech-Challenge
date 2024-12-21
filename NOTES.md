# AWS Challenge Notes

### Notes
* Installation of httpd: Scripting the installation of httpd was not feasible because the ASG instances are in a subnet without internet access. To resolve this, I added a NAT gateway in the public subnet and updated the route tables to allow outbound traffic for the ASG instances to update and install necessary packages.

* ALB Configuration: Shouldn't the ALB (Application Load Balancer) handle and terminate HTTPS traffic, then forward it to the instances over HTTP rather than the other way around? This setup would require an ACM certificate.

---

## General Documentation
* https://registry.terraform.io/providers/hashicorp/aws

## EC2 and EBS
* Attaching EBS to EC2:
  - https://www.geeksforgeeks.org/how-to-create-an-aws-ec2-instance-and-attach-ebs-to-ec2-with-terraform/

* AMI Selection:
  - https://access.redhat.com/solutions/15356#us_east_2
  - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami

## ASG and IAM
* Auto Scaling and Load Balancing:
  - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
  - https://developer.hashicorp.com/terraform/tutorials/aws/aws-asg (Didnt work for ASG, good for ALB)
  - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template

* IAM Resources:
  - https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html
  - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile
  - Visual IAM Policy editor in AWS console (to copy the json format)

## Other Resources
* Utility:
  - https://developer.hashicorp.com/terraform/language/functions/base64encode
  - https://stackoverflow.com/questions/60911338/reference-to-other-module-resource-in-terraform

* S3:
  - https://stackoverflow.com/questions/37491893/how-to-create-a-folder-in-an-aws-s3-bucket-using-terraform
