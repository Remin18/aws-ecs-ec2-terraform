variable "project_prefix" {
  description = "Name of the project prefix"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "exec_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "instance_profile_arn" {
  description = "ARN of the ECS instance profile"
  type        = string
}

variable "ecs_instance_type" {
  description = "Instance type for ECS instances"
  type        = string
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
