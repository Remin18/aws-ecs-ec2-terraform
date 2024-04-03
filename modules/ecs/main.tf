resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"
}

resource "aws_security_group" "ecs_sg" {
  name   = "${var.project_name}-ecs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ssm_parameter" "amzn_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

resource "aws_launch_template" "ecs_ec2" {
  name                   = "${var.project_name}-ecs-ec2-template"
  image_id               = data.aws_ssm_parameter.amzn_ami.value
  instance_type          = var.ecs_instance_type
  vpc_security_group_ids = [aws_security_group.ecs_sg.id]

  iam_instance_profile { arn = var.instance_profile_arn }
  monitoring { enabled = true }

  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config;
      mkdir -p ${var.source_path}
      echo -e "${var.nfs_dns_name}:/${var.junction_path}\t${var.source_path}\tnfs\tnfsvers=4,_netdev,noresvport,defaults\t0\t0" | tee -a /etc/fstab
      systemctl daemon-reload
      mount -a
      chmod 775 ${var.source_path}
      chown 1000:1000 ${var.source_path}
    EOF
  )
}

resource "aws_autoscaling_group" "ecs" {
  name                      = "${var.project_name}-ecs-asg"
  vpc_zone_identifier       = var.subnet_ids
  health_check_grace_period = 0
  health_check_type         = "EC2"
  protect_from_scale_in     = false
  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 1

  launch_template {
    id      = aws_launch_template.ecs_ec2.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ecs-instance"
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "this" {
  name = "${var.project_name}-ecs-ec2-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = [aws_ecs_capacity_provider.this.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    base              = 1
    weight            = 100
  }
}

resource "aws_cloudwatch_log_group" "jenkins" {
  name              = "${var.project_name}-log"
  retention_in_days = 14
}

resource "aws_ecs_task_definition" "jenkins" {
  family             = "${var.project_name}-taskdef"
  network_mode       = "bridge"
  cpu                = 512
  memory             = 512
  execution_role_arn = var.exec_role_arn
  task_role_arn      = var.task_role_arn

  volume {
    name      = var.source_volume
    host_path = var.source_path
  }

  container_definitions = jsonencode([
    {
      name  = "jenkins"
      image = "jenkins/jenkins:lts"
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        },
        {
          containerPort = 50000
          hostPort      = 50000
        }
      ]
      environment = [
        {
          name  = "JAVA_OPTS"
          value = "-Duser.timezone=Asia/Tokyo -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8 -Xmx1524m -Xms256m"
        }
      ]
      mountPoints = [
        {
          sourceVolume   = var.source_volume
          containerPath  = var.container_path
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.jenkins.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "jenkins" {
  name                   = "${var.project_name}-ecs-service"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.jenkins.arn
  desired_count          = 1
  enable_execute_command = true

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    base              = 1
    weight            = 100
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}
