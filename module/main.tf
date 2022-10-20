locals {
  docker_build_s3_prefix = "docker-deploy/${var.project_name}"
  buildspec_file         = "buildspec.yml"
}

# Docker Files & Resources          ------------------------------------------------------------------------------------
resource "aws_ecr_repository" "docker_repo" {
  name                 = var.project_name,
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }
}

data "aws_ecr_authorization_token" "docker_token" {
  registry_id = aws_ecr_repository.docker_repo.registry_id
  depends_on  = [aws_ecr_repository.docker_repo]
}

resource "aws_s3_bucket_object" "docker_files" {
  for_each    = fileset(var.local_docker_dir, "**/*")
  bucket      = var.s3_bucket.id
  key         = "${local.docker_build_s3_prefix}/${each.value}"
  source      = "${var.local_docker_dir}/${each.value}"
  source_hash = filemd5("${var.local_docker_dir}/${each.value}")
}

resource "aws_s3_bucket_object" "buildspec" {
  bucket  = var.s3_bucket.id
  key     = "${local.docker_build_s3_prefix}/${local.buildspec_file}"
  content = templatefile("${path.module}/${local.buildspec_file}", {
    region_name = var.region_name
    account_id  = var.account_id
    docker_tag  = var.project_name
  })
  source_hash = filemd5("${path.module}/${local.buildspec_file}")
}

# Docker Codebuild                --------------------------------------------------------------------------------------
resource "aws_codebuild_project" "docker_deploy" {
  name          = var.project_name
  description   = "Codebuild project to deploy ${var.project_name} Docker to ECR."
  build_timeout = var.build_timeout
  service_role  = var.codebuild_iam_role_arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = var.codebuild_compute_type
    image           = var.codebuild_image
    type            = var.codebuild_container_type
    privileged_mode = true

    dynamic "environment_variable" {
      for_each = var.codebuild_environment_variables
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
      }
    }
  }
  source {
    type     = "s3"
    location = "${var.s3_bucket.bucket}/${local.docker_build_s3_prefix}"
  }

  vpc_config {
    security_group_ids = var.codebuild_security_group_ids
    subnets            = var.codebuild_vpc_subnets
    vpc_id             = var.codebuild_vpc_id
  }

  depends_on = [aws_ecr_repository.docker_repo, aws_s3_bucket_object.buildspec, aws_s3_bucket_object.docker_files]
}

# S3 Put Event & Lambda                ---------------------------------------------------------------------------------
data "archive_file" "lambda_script" {
  type             = "zip"
  source_file      = "${path.module}/lambda_function.py"
  output_path      = "${path.module}/lambda_function.zip"
  output_file_mode = "0666"
}

resource "aws_lambda_function" "lambda_function" {
  function_name    = "${var.project_name}-docker-codebuild"
  role             = var.lambda_role
  filename         = data.archive_file.lambda_script.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_script.output_path)
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  timeout          = 60
  memory_size      = 128

  vpc_config {
    security_group_ids = var.lambda_security_group_ids
    subnet_ids         = var.lambda_subnet_ids
  }
}

resource "aws_s3_bucket_notification" "put_event" {
  bucket = var.s3_bucket.bucket

  dynamic "lambda_function" {
    for_each = fileset(var.local_docker_dir, "**/*")
    content {
      lambda_function_arn = aws_lambda_function.lambda_function.arn
      events              = ["s3:ObjectCreated:*"]
      filter_prefix       = "${local.docker_build_s3_prefix}/${lambda_function.value}"
    }
  }
}