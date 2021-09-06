output "ecs_cluster_arn" {
  value = aws_ecs_cluster.example.arn
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.example.name
}

output "ecs_service_name" {
  value = aws_ecs_service.example.name
}
