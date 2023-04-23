output "schedule_group_name" {
  description = "Name of the Schedule Group"
  value       = aws_scheduler_schedule_group.schedule_group.name
}
