resource "aws_ecr_repository" "repo" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_repository_arn" {
  value = aws_ecr_repository.repo.arn
}

output "ecr_repository_name" {
  value = aws_ecr_repository.repo.name
}

output "ecr_repository_registry_id" {
  value = aws_ecr_repository.repo.registry_id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.repo.repository_url
}