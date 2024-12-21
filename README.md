# AWS Technical Challenge - Coalfire

## Deliverables

- **GitHub Repository**: [Link to Repository](https://github.com/asian-code/Coalfire-Tech-Challenge)
- **Architecture Diagram**:
  ![Architecture Diagram](https://github.com/asian-code/Coalfire-Tech-Challenge/blob/master/Other/diagram.png)
- **EC2 Instance Screenshot**:
  ![EC2 Screenshot](https://github.com/asian-code/Coalfire-Tech-Challenge/blob/master/Other/coalfire-ec2-screenshot.png)

## Architecture Components

### Network Infrastructure

- **VPC Configuration**
  - CIDR Block: `10.1.0.0/16`
  - Region: Multi-AZ deployment

- **Subnet Layout**
  | Subnet | CIDR Block | Access Type | Purpose |
  |--------|------------|-------------|----------|
  | Sub1 | `10.1.0.0/24` | Public | Internet-facing resources |
  | Sub2 | `10.1.1.0/24` | Public | EC2 instance hosting |
  | Sub3 | `10.1.2.0/24` | Private | ASG deployment |
  | Sub4 | `10.1.3.0/24` | Private | ASG deployment |

### Compute Resources

#### EC2 Instance `MyVM`
- Location: Sub2 (Public subnet)
- Specifications:
  - OS: Red Hat Linux (RHEL 9)
  - Instance Type: t2.micro
  - Storage: 20 GB
  - Access: SSH key authentication

#### Auto Scaling Group (ASG)
- Deployment: Sub3 and Sub4 (Private subnets)
- Configuration:
  - Scale: 2-6 instances
  - Template: Apache web server (`httpd`)
  - IAM Integration: Read access to Images bucket, write access to Logs bucket

### Load Balancing

- **Application Load Balancer**
  - Listener: HTTP (`Port 80`)
  - Target: ASG instances (`Port 443`)
  - Distribution: Cross-AZ load balancing

### Storage Solutions

#### S3 Buckets

**Images Bucket** (`eric-coalfire-images`)
- Structure:
  - `/archive`
  - `/memes`
- Lifecycle Policy: 90-day Glacier transition for `/memes`

**Logs Bucket** (`eric-coalfire-logs`)
- Structure:
  - `/Active` → Glacier after 90 days
  - `/Inactive` → Delete after 90 days

### Security Configuration

#### Security Groups

| Group | Purpose | Rules |
|-------|----------|-------|
| `MyVM-sg` | EC2 in Sub2 | Inbound: SSH only |
| `private-sg` | ASG instances | Inbound: HTTPS from ALB |
| `alb-sg` | Load Balancer | Inbound: HTTP, Outbound: HTTPS to ASG |

#### Network Gateway
- NAT Gateway deployed in public subnet
- Enables internet access for private subnets

#### IAM Roles
- ASG Instance profile Role: Read access to Images bucket
- logs Role: Write access to Logs bucket

---
#### Variables

| Name | Description | type | default | required |
|-------|----------|-------|-------|-------|
| region | the region where resources will be created in | string | "us-east-2" | no
| vpc_cidr | the cidr of the main vpc | string | "10.1.0.0/16" | no
| ec2_type | the VM instance type `ex:t3.micro` | string | "t2.micro" | no
| private_subnets | cidr of the `private` subnets to create | map(string) | `{
    subnet3 = "10.1.2.0/24"
    subnet4 = "10.1.3.0/24"
  }` | no
| public_subnets | cidr of the `public` subnets to create | map(string) | `{
    subnet1 = "10.1.0.0/24"
    subnet2 = "10.1.1.0/24"
  }` | no
| ec2_key_name | key pair name used to connect to ec2 | string | "hehe" | yes
| images_bucket_name | name of the s3 bucket to store images | string | "eric-coalfire-images" | no
| logs_bucket_name | name of the s3 bucket to store logs | string | "eric-coalfire-logs" | no
| image_folders | list of folders to create in images s3 bucket | list(string) | ["archive", "memes"] | no
| log_folders | list of folders to create in logs s3 bucket | list(string) | ["Active folder", "Inactive folder"] | no

#### Outputs
| Name | Description |
|------|-------------|
| instance_id | ID of ec2 in subnet2 |
| images_bucket_arn | The ARN of the images bucket |
| log_bucket_arn | The ARN of the logs bucket |
| alb_arn | The ARN of the App load balancer that points to the ASG |

