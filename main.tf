terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.42.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "iam" {
  source = "./modules/iam"

  project_prefix = var.project_prefix
  region         = var.region
}

module "ecs" {
  source = "./modules/ecs"

  project_name         = var.project_name
  region               = var.region
  vpc_id               = var.vpc_id
  subnet_ids           = var.subnet_ids
  ecs_instance_type    = var.ecs_instance_type
  source_volume        = var.source_volume
  source_path          = var.source_path
  container_path       = var.container_path
  junction_path        = var.junction_path
  nfs_dns_name         = var.nfs_dns_name
  exec_role_arn        = module.iam.exec_role_arn
  task_role_arn        = module.iam.task_role_arn
  instance_profile_arn = module.iam.instance_profile_arn
}
