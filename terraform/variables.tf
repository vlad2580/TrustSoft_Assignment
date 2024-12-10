variable "region" {
  description = "AWS region for resources"
  default     = "eu-west-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance -  Ubuntu"
  default     = "ami-0e9085e60087ce171"
}

variable "ebs_volume_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 20
}

variable "ebs_volume_type" {
  description = "Type of the EBS volume"
  type        = string
  default     = "gp3"
}


variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = "app-load-balancer"
}

variable "target_group_name" {
  description = "Name of the Target Group"
  type        = string
  default     = "target-group"
}

variable "security_group_name" {
  description = "Name of the security group"
  type        = string
  default     = "sg_internship_vladislav"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
