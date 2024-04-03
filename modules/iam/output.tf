output "exec_role_arn" {
  description = "exec role arn"
  value       = aws_iam_role.ecs_exec_role.arn
}

output "task_role_arn" {
  description = "task role arn"
  value       = aws_iam_role.ecs_task_role.arn
}

output "instance_profile_arn" {
  description = "instance profile arn"
  value       = aws_iam_instance_profile.ecs_instance_profile.arn
}
