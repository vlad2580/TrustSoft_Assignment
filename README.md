# TrustSodt_Assignment
# **Project Description**

This project uses **Terraform** to deploy a comprehensive **AWS infrastructure**. The deployed resources include **VPC**, **subnets**, **EC2 instances**, **Application Load Balancer (ALB)**, **Security Groups**, **IAM roles**, **S3 backend**, **NAT Gateway**, **Route Tables**, and **Route Associations**.

The primary goal of this project is to demonstrate **Infrastructure as Code (IaC)** principles and provide a production-ready environment for web applications running on **EC2 instances** behind an **ALB**.

---

## **Project Resources**

This project deploys the following AWS infrastructure:

### **Network**
- **VPC** with a custom CIDR block (`10.0.0.0/16` by default)
- **2 public and 2 private subnets**
- **Internet Gateway**
- **NAT Gateway** for outbound internet access for private instances
- **Route Tables** with public and private routing configurations
- **Route Table Associations** to link subnets to route tables

### **Compute**
- **2 EC2 instances** in **separate private subnets** (1 in each AZ) running **Apache2**
- Each EC2 instance is placed in its own private subnet to ensure **high availability** and **security**
  - **EC2 instance 1** is deployed in **private subnet 1**  
  - **EC2 instance 2** is deployed in **private subnet 2**  
- **IAM Instance Profile** to allow management of EC2 instances via **AWS SSM**

### **Load Balancing**
- **Application Load Balancer (ALB)** to distribute incoming traffic to EC2 instances
- **Target Group** for backend instances with **health check configurations**

### **Security**
- **Security Group** to control **inbound and outbound traffic** for EC2 and ALB
  - **Inbound**: Allows HTTP (port 80) traffic to the ALB
  - **Outbound**: Full outbound access for EC2 instances to enable software updates and package downloads

### **Backend**
- **S3 Bucket** to store **Terraform state file**
- **DynamoDB Table** for **state lock management** to ensure only one user or system can modify the infrastructure at a time

## **Usage**

To deploy this infrastructure, follow the steps below.

### **1️⃣ Prerequisites**
Make sure you have the following installed and configured on your system:
- **AWS CLI** (v2.0 or higher)
- **Terraform** (v1.5 or higher)
- Access to an AWS account with sufficient permissions to create resources:
  - **EC2**
  - **IAM**
  - **S3**
  - **VPC**
  - **DynamoDB**

Run the following command to configure AWS CLI credentials:
```bash
aws configure
```
### **2️⃣ Clone the repository**

Clone this repository to your local machine:
```bash
git clone https://github.com/your-repo/terraform-aws-infrastructure.git
cd terraform-aws-infrastructure
```

### **3️⃣ Initialize Terraform**

Run the following command to initialize **Terraform**. It will download all necessary providers and set up the S3 backend.
```bash
сd backend
terraform init
```
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.67.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_backend"></a> [backend](#module\_backend) | ./backend | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_eip.nat_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_instance_profile.ec2_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.ec2_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ec2_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.web_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_lb.app_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.tg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.tg_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_nat_gateway.ngw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private_internet_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_internet_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private_1_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private_2_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public_assoc1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public_assoc2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.allow_tls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.privateSB1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.privateSB2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.publicSB1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.publicSB2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_name"></a> [alb\_name](#input\_alb\_name) | Name of the Application Load Balancer | `string` | `"app-load-balancer"` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI ID for the EC2 instance -  Ubuntu | `string` | `"ami-0e9085e60087ce171"` | no |
| <a name="input_ebs_volume_size"></a> [ebs\_volume\_size](#input\_ebs\_volume\_size) | Size of the EBS volume in GB | `number` | `20` | no |
| <a name="input_ebs_volume_type"></a> [ebs\_volume\_type](#input\_ebs\_volume\_type) | Type of the EBS volume | `string` | `"gp3"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type | `string` | `"t2.micro"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for resources | `string` | `"eu-west-1"` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Name of the security group | `string` | `"sg_internship_vladislav"` | no |
| <a name="input_target_group_name"></a> [target\_group\_name](#input\_target\_group\_name) | Name of the Target Group | `string` | `"target-group"` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ec2_instance_ids"></a> [ec2\_instance\_ids](#output\_ec2\_instance\_ids) | output "kms\_key\_arn" { value = aws\_kms\_key.ec2\_ebs\_key.arn } |
