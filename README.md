# AWS Technical Challenge Coalfire
---

## Deliverables
1. **GitHub Repository**: [Link to Repository](#)
2. **Architecture Diagram**: [Insert image reference in github]
3. **EC2 Instance Screenshot**: [Insert image reference in github]
4. **Solution Write-Up**
5. **Functional README**: 

---

## Architecture Design
The AWS architecture includes the following components:
- **1 VPC**: CIDR `10.1.0.0/16`.
- **4 Subnets**:
  - Sub1: `10.1.0.0/24` (Internet Accessible).
  - Sub2: `10.1.1.0/24` (Internet Accessible).
  - Sub3: `10.1.2.0/24` (Not Internet Accessible).
  - Sub4: `10.1.3.0/24` (Not Internet Accessible).
- **1 EC2 Instance** in Sub2.
- **Auto Scaling Group (ASG)** for Sub3 and Sub4.
- **Application Load Balancer (ALB)** for HTTP (port 80) traffic.
- **S3 Buckets**:
  - "Images" bucket with lifecycle policy to move objects older than 90 days to Glacier.
  - "Logs" bucket with lifecycle policies for Active and Inactive folders.
- **IAM Roles** for log writing and S3 bucket access.

### Architecture Diagram
[Insert the diagram of the AWS architecture here.]

---

## Implementation Details

### VPC and Subnets
- Created a VPC with CIDR `10.1.0.0/16`.
- Subnets spread across two availability zones:
  - Sub1 and Sub2 are public and internet accessible.
  - Sub3 and Sub4 are private and isolated from the internet.

### EC2 Instance
- Configured an EC2 instance in Sub2 with:
  - **OS**: Red Hat Linux.
  - **Instance Type**: `t2.micro`.
  - **Storage**: 20 GB.
- Verified access by logging into the instance.

### Auto Scaling Group (ASG)
- Configured an ASG to deploy instances in Sub3 and Sub4:
  - Used a launch template to install Apache web server (`httpd`).
  - Configured scaling policies for a minimum of 2 and maximum of 6 instances.
  - Attached an IAM role for reading from the "Images" bucket.

### Application Load Balancer (ALB)
- Configured an ALB to:
  - Listen on TCP port 80 (HTTP).
  - Forward traffic to ASG instances on port 443.

### S3 Buckets
- **"Images" Bucket**:
  - Folder: `archive`.
  - Lifecycle Policy: Move objects older than 90 days to Glacier.
- **"Logs" Bucket**:
  - Folders: `Active` and `Inactive`.
  - Lifecycle Policies:
    - `Active`: Move objects older than 90 days to Glacier.
    - `Inactive`: Delete objects older than 90 days.

### IAM Roles
- Configured roles to:
  - Allow ASG instances to read from the "Images" bucket.
  - Allow EC2 instances to write logs to the "Logs" bucket.

---

## Challenges and Solutions
1. **Networking Configuration**: Ensured proper routing and security groups for public and private subnets.
2. **IAM Role Configuration**: Created least privilege policies for accessing S3 buckets.
3. **Automation**: Used Terraform modules to simplify resource creation.

---

## References
- [Backend setup](https://developer.hashicorp.com/terraform/language/backend/s3)
- [Coalfire Terraform Modules](https://github.com/orgs/Coalfire-CF/repositories?type=public&q=terraform-aws)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Red Hat EC2 Setup](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/)

---

## Next Steps
1. Finalize and upload all artifacts to the GitHub repository.
2. Share the GitHub repository link and documentation with the recruiting POC.

---
