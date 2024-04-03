variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet ID"
  type        = list(string)
}

variable "ecs_instance_type" {
  description = "Instance type for ECS instances"
  type        = string
  default     = "t3.micro"
}

variable "source_volume" {
  description = "NFS source volume"
  type        = string
}

variable "source_path" {
  description = "NFS source path"
  type        = string
}

variable "container_path" {
  description = "Mount path inside the container"
  type        = string
}

variable "junction_path" {
  description = "NFS junction path"
  type        = string
}

variable "nfs_dns_name" {
  description = "DNS name of the NFS server"
  type        = string
}
