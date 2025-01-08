# TrustSoft_Assignment


# **Project Description**

This project uses **Terraform** to deploy a comprehensive **AWS infrastructure**. The deployed resources include **VPC**, **subnets**, **EC2 instances**, **Application Load Balancer (ALB)**, **Security Groups**, **IAM roles**, **S3 backend**, **NAT Gateway**, **Route Tables**, and **Route Associations**.

The primary goal of this project is to demonstrate **Infrastructure as Code (IaC)** principles and provide a production-ready environment for web applications running on **EC2 instances** behind an **ALB**.

### This architecture diagram represents the infrastructure setup

![TrustSoft_Diagram](https://github.com/user-attachments/assets/6d1a96b2-fb16-4241-86b9-9f610703d0db)

---

## **Usage**

To deploy this infrastructure, follow the steps below.

### **1️⃣ Prerequisites**

Make sure you have the following installed and configured on your system:

- **AWS CLI** (v2.0 or higher)
- **Terraform** (v1.5 or higher)
- **SSM Agent**(installed and running on all EC2 instances; pre-installed on most Amazon Linux and Ubuntu AMIs)
- Access to an AWS account with sufficient permissions to create resources:
  - **EC2**
  - **IAM**
  - **S3**
  - **VPC**
  - **DynamoDB**

### **2️⃣ Clone the repository**

Clone this repository to your local machine:

```bash
git clone https://github.com/your-repo/terraform-aws-infrastructure.git
cd terraform-aws-infrastructure
```

### **3️⃣ AWS CLI CONFIGIRATION**

Run the following commands in your terminal to set the AWS environment variables. Learn more

```bash
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"
export AWS_SESSION_TOKEN="YOUR_SESSION_TOKEN"
```

### **4️⃣ Initialize and deploy Terraform backend**

Run the following command to initialize **Terraform**. It will download all necessary providers and set up the S3 backend.After that id will deploy **S3 bucket** for storing state file and **DynamoDb table** for lock

```bash
сd backend
terraform init
terraform plan
terraform fmt
terraform validate
terraform apply
```

### **5️⃣ Deploy the Infrastructure**

Once the Terraform backend is initialized, and the S3 bucket and DynamoDB table are set up, you can proceed to deploy the main infrastructure.

**Steps to Deploy:**

- Navigate to the root Terraform directory:

```bash
cd ../
```

- Initialize,format and validate Terraform in the main directory

```bash
terraform init
terraform validate
terraform fmt
```

- Plan the infrastructure deployment to see what resources will be created

```bash
terraform plan
```

- Apply the infrastructure deployment:

```bash
terraform apply
```

### **6️⃣ Verify the Deployment**

- At the end of the terraform apply command, you should see the output with the DNS name of the Application Load Balancer (ALB).

Example:

```bash
Outputs:

alb_dns_name = "app-load-balancer-XXXXXXXXXX.<your_region>.elb.amazonaws.com"
ec2_instance_ids = [
    "i-0XXXXXXXXXX",
    "i-0XXXXXXXXXX"
]
```

- Copy the alb_dns_name from the output and paste it into your browser:

```bash
http://app-load-balancer-XXXXXXXXXX.<your_region>.elb.amazonaws.com
```

- Plan the infrastructure deployment to see what resources will be created

```bash
terraform plan
```

- You should see a response from one of the EC2 instances:

```bash
		“Hello from server 1”
                or
		“Hello from server 2”
```

# Troubleshooting

If you encounter issues during or after deployment, follow these steps to troubleshoot common problems:

**1️⃣ Checking Health Checks in the AWS Management Console**

The Application Load Balancer (ALB) uses health checks to ensure that EC2 instances are available to serve traffic. If the ALB is not routing traffic correctly, verify the health status of the target instances.

In AWS console go to the
/
**EC2 Dashboard** -> **Target Groups** -> **Health Status**
/

Verify that all attached instances show the status as healthy.

**2️⃣ Connecting to EC2 Instances Using SSM**

If you need to debug an issue directly on the EC2 instances, use **AWS Systems Manager Session Manager (SSM)** to connect.

```bash
aws ssm start-session --target <INSTANCE_ID> --region <YOUR_REGION>
```

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

# **Logging Documentation**

```bash
logging.tf
```

## **1. VPC Flow Logs**

### **Purpose**

Enable logging of VPC network traffic to **CloudWatch Logs** for visibility and troubleshooting.

### **Steps to Implement**

1. **Create CloudWatch Log Group**:

   - **Name**: `/aws/vpc/flow-logs`
   - **Retention**: **2 days** (currently set to 3, needs adjustment).

2. **Create IAM Role and Policy**:

   - **IAM Role**: `vpc-flow-logs-role` allows VPC Flow Logs to send log data to **CloudWatch**.
   - **IAM Policy**: Grants permissions to create log groups, log streams, and send logs.

3. **Enable VPC Flow Logs**:
   - **Traffic Type**: Captures **ALL** traffic (inbound & outbound) for the VPC.
   - **Log Destination**: **CloudWatch Logs**.
   - **Role**: Uses **vpc-flow-logs-role** for permissions.

### **Key Resources**

- **CloudWatch Log Group**: `/aws/vpc/flow-logs`
- **IAM Role**: `vpc-flow-logs-role`
- **IAM Policy**: Grants permissions
- **VPC Flow Log**: Captures **ALL** traffic for the VPC and sends it to **CloudWatch Logs**.

---

## **2. SNS for CloudWatch Alarms**

### **Purpose**

Send alert notifications for **CloudWatch Alarms** to email subscribers.

### **Steps to Implement**

1. **Create SNS Topic**:

   - **Name**: `cloudwatch-ec2-alarms-topic`

2. **Create Email Subscription**:
   - **Email**: Provided via variable `var.sns_email`.
   - **Protocol**: **Email**.

### **Key Resources**

- **SNS Topic**: `cloudwatch-ec2-alarms-topic`
- **SNS Subscription**: Subscribes an email (provided as `var.sns_email`) to receive notifications.

---

## **3. CloudWatch Alarms for EC2**

### **Purpose**

Monitor **EC2 CPU utilization** and trigger SNS alerts on high usage.

### **Steps to Implement**

1. **Create CloudWatch Alarm**:

   - **Metric**: **CPUUtilization**.
   - **Threshold**: Trigger alarm if CPU usage is **80% or higher for 2 consecutive periods** of 60 seconds.

2. **Send Alerts via SNS**:
   - Sends notifications to **SNS topic** `cloudwatch-ec2-alarms-topic`.

### **Key Resources**

- **CloudWatch Alarm**: Monitors **CPUUtilization**. If usage exceeds **80%**, the alarm triggers and sends alerts via **SNS topic**.
- **SNS Topic**: Used to send alerts for alarm breaches.

---

## **4. CloudWatch Agent (Optional)**

### **Purpose**

Enable collection of additional EC2 metrics (e.g., **memory, disk usage**) using **CloudWatch Agent**.

### **Steps to Implement**

1. **Create SSM Parameter**:

   - Store **CloudWatch Agent configuration** in **SSM Parameter Store**.

2. **Create SSM Document**:

   - Create a **custom SSM document** to install and configure the CloudWatch Agent on **EC2 instances**.

3. **Apply Configuration via SSM Association**:
   - Automatically install and configure the **CloudWatch Agent** on EC2 instances with specific tags (e.g., **webServer1, webServer2**).

### **Key Resources**

- **SSM Parameter**: Stores the configuration for CloudWatch Agent (CPU, Disk, and Memory metrics).
- **SSM Document**: Custom script to download, install, and configure the **CloudWatch Agent**.
- **SSM Association**: Applies the CloudWatch Agent configuration to **tagged EC2 instances**.

---

## Requirements

| Name                                                   | Version |
| ------------------------------------------------------ | ------- |
| <a name="requirement_aws"></a> [aws](#requirement_aws) | ~> 4.0  |

## Providers

| Name                                             | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | 4.67.0  |

## Modules

| Name                                                     | Source    | Version |
| -------------------------------------------------------- | --------- | ------- |
| <a name="module_backend"></a> [backend](#module_backend) | ./backend | n/a     |

## Resources

| Name                                                                                                                                                                     | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------- |
| [aws_cloudwatch_log_group.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)                               | resource    |
| [aws_cloudwatch_metric_alarm.ec2_cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm)                               | resource    |
| [aws_eip.nat_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip)                                                                       | resource    |
| [aws_flow_log.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log)                                                       | resource    |
| [aws_iam_instance_profile.ec2_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile)                        | resource    |
| [aws_iam_policy.vpc_flow_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)                                            | resource    |
| [aws_iam_role.ec2_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                            | resource    |
| [aws_iam_role.vpc_flow_logs_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                  | resource    |
| [aws_iam_role_policy_attachment.ec2_cloudwatch_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)           | resource    |
| [aws_iam_role_policy_attachment.ec2_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)                      | resource    |
| [aws_iam_role_policy_attachment.vpc_flow_logs_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource    |
| [aws_instance.web_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)                                                          | resource    |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway)                                                 | resource    |
| [aws_lb.app_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb)                                                                          | resource    |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener)                                                          | resource    |
| [aws_lb_target_group.tg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group)                                                    | resource    |
| [aws_lb_target_group_attachment.tg_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment)                   | resource    |
| [aws_nat_gateway.ngw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway)                                                           | resource    |
| [aws_route.private_internet_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route)                                                   | resource    |
| [aws_route.public_internet_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route)                                                    | resource    |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table)                                                       | resource    |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table)                                                        | resource    |
| [aws_route_table_association.private_1_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association)                       | resource    |
| [aws_route_table_association.private_2_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association)                       | resource    |
| [aws_route_table_association.public_assoc1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association)                         | resource    |
| [aws_route_table_association.public_assoc2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association)                         | resource    |
| [aws_security_group.allow_tls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                               | resource    |
| [aws_sns_topic.cloudwatch_alarm_topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic)                                            | resource    |
| [aws_sns_topic_subscription.email_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription)                      | resource    |
| [aws_ssm_association.apply_cloudwatch_agent_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_association)                         | resource    |
| [aws_ssm_document.custom_cloudwatch_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document)                                    | resource    |
| [aws_ssm_parameter.cloudwatch_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter)                                         | resource    |
| [aws_subnet.privateSB1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet)                                                              | resource    |
| [aws_subnet.privateSB2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet)                                                              | resource    |
| [aws_subnet.publicSB1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet)                                                               | resource    |
| [aws_subnet.publicSB2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet)                                                               | resource    |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)                                                                          | resource    |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)                                            | data source |

## Inputs

| Name                                                                                       | Description                                             | Type          | Default                                                                    | Required |
| ------------------------------------------------------------------------------------------ | ------------------------------------------------------- | ------------- | -------------------------------------------------------------------------- | :------: |
| <a name="input_alb_name"></a> [alb_name](#input_alb_name)                                  | Name of the Application Load Balancer                   | `string`      | `"app-load-balancer"`                                                      |    no    |
| <a name="input_ami_id"></a> [ami_id](#input_ami_id)                                        | AMI ID for the EC2 instance - Ubuntu                    | `string`      | `"ami-0e9085e60087ce171"`                                                  |    no    |
| <a name="input_default_tags"></a> [default_tags](#input_default_tags)                      | Default tags to apply to all resources                  | `map(string)` | <pre>{<br/> "Environment": "internship",<br/> "Project": "vpc"<br/>}</pre> |    no    |
| <a name="input_ebs_volume_size"></a> [ebs_volume_size](#input_ebs_volume_size)             | Size of the EBS volume in GB                            | `number`      | `20`                                                                       |    no    |
| <a name="input_ebs_volume_type"></a> [ebs_volume_type](#input_ebs_volume_type)             | Type of the EBS volume                                  | `string`      | `"gp3"`                                                                    |    no    |
| <a name="input_instance_type"></a> [instance_type](#input_instance_type)                   | EC2 instance type                                       | `string`      | `"t2.micro"`                                                               |    no    |
| <a name="input_region"></a> [region](#input_region)                                        | AWS region for resources                                | `string`      | `"eu-west-1"`                                                              |    no    |
| <a name="input_security_group_name"></a> [security_group_name](#input_security_group_name) | Name of the security group                              | `string`      | `"sg_internship_vladislav"`                                                |    no    |
| <a name="input_sns_email"></a> [sns_email](#input_sns_email)                               | Email address to receive CloudWatch Alarm notifications | `string`      | n/a                                                                        |   yes    |
| <a name="input_target_group_name"></a> [target_group_name](#input_target_group_name)       | Name of the Target Group                                | `string`      | `"target-group"`                                                           |    no    |
| <a name="input_vpc_cidr_block"></a> [vpc_cidr_block](#input_vpc_cidr_block)                | CIDR block for the VPC                                  | `string`      | `"10.0.0.0/16"`                                                            |    no    |

## Outputs

| Name                                                                                      | Description                               |
| ----------------------------------------------------------------------------------------- | ----------------------------------------- |
| <a name="output_alb_dns_name"></a> [alb_dns_name](#output_alb_dns_name)                   | DNS Name of the Application Load Balancer |
| <a name="output_ec2_instance_ids"></a> [ec2_instance_ids](#output_ec2_instance_ids)       | IDs of created EC2 instances              |
| <a name="output_private_subnet_ids"></a> [private_subnet_ids](#output_private_subnet_ids) | List of private subnet IDs                |
| <a name="output_public_subnet_ids"></a> [public_subnet_ids](#output_public_subnet_ids)    | List of public subnet IDs                 |
| <a name="output_ssm_association_id"></a> [ssm_association_id](#output_ssm_association_id) | ID созданной SSM Association              |
| <a name="output_vpc_id"></a> [vpc_id](#output_vpc_id)                                     | The ID of the VPC                         |
