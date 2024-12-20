# AWS Technical Challenge Coalfire
---

## Deliverables
1. **GitHub Repository**: [Link to Repository](https://github.com/asian-code/Coalfire-Tech-Challenge)
2. **Architecture Diagram**: ![Diagram](https://github.com/asian-code/Coalfire-Tech-Challenge/blob/master/Other/diagram.png)

3. **EC2 Instance Screenshot**: ![Screenshot](https://github.com/asian-code/Coalfire-Tech-Challenge/blob/master/Other/coalfire-ec2-screenshot.png)
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
- **IAM Roles** for log writing into Logs bucket and read access to images bucket.

### Architecture Diagram


---

## Implementation Details

### VPC and Subnets
- Created a VPC with CIDR `10.1.0.0/16`.
- Subnets spread across two availability zones:
  - Sub1 and Sub2 are public and internet accessible.
  - Sub3 and Sub4 are private and isolated from the internet.

### EC2 Instance
- Configured an EC2 instance in Sub2 with:
  - **OS**: Red Hat Linux 9
  - **Instance Type**: `t2.micro`.
  - **Storage**: 20 GB.
  - **Security**: SSH Key authenication
- Verified access by logging into the instance via key file.

### Auto Scaling Group (ASG)
- Configured an ASG to deploy instances in Sub3 and Sub4:
  - Used a launch template to install Apache web server (`httpd`).
  - Configured scaling policies for a minimum of 2 and maximum of 6 instances.
  - Attached an IAM role for reading from the "Images" bucket.

### Application Load Balancer (ALB)
- Configured an ALB to:
  - Listen on TCP port 80 (HTTP).
  - Forward traffic to ASG instances on port 443 via target group.

### S3 Buckets
- **"Images" Bucket (eric-coalfire-images)**:
  - Folders: `archive` and `memes`.
  - Lifecycle Policy: Move "memes" objects older than 90 days to Glacier.
- **"Logs" Bucket (eric-coalfire-logs)**:
  - Folders: `Active` and `Inactive`.
  - Lifecycle Policies:
    - `Active`: Move objects older than 90 days to Glacier.
    - `Inactive`: Delete objects older than 90 days.

### IAM Roles
- Configured roles to:
  - Allow ASG instances to read from the "Images" bucket.
  - Allow EC2 instances to write logs to the "Logs" bucket.

### Security Groups
- Configured "public-sg" security group to: ec2 in sub2
  - allow only SSH traffic inbound
- Configured "private-sg" security group to: asg instances
  - allow incoming HTTPS traffic from ALB (alb-sg)
- Configured "alb-sg" security group to: alb
  - allow incoming HTTP traffic
  - allow outbound HTTPS traffic to ASG instances (priavte-sg)

### Nat Gateway
- Configured an NG on public subnet to allow private subnets to access the internet
