variable "region_name" {
  description = "The region where the image will be deployed."
  type        = string
}

variable "account_id" {
  description = "The account where the image will be deployed."
}

# Docker Files & Resources          ------------------------------------------------------------------------------------
variable "image_tag_mutability" {
  description = "Set the tag mutability of the ECR repo."
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Scan the docker image is it is pushed to ECR."
  type        = bool
  default     = true
}

variable "project_name" {
  description = "The name of your Docker Deployment Project."
  type        = string
}

variable "local_docker_dir" {
  description = "The local directory where the Dockerfile is found."
  type        = string
}

variable "s3_bucket" {
  description = "The S3 Bucket that will contain the codebuild repository, and will include a put event trigger to build the docker image."
}

# Docker Codebuild                --------------------------------------------------------------------------------------
variable "build_timeout" {
  description = "The codebuild timeout in seconds."
  type        = number
  default     = 60
}

variable "codebuild_iam_role_arn" {
  description = "The ARN for the Codebuild IAM Role."
}

variable "codebuild_compute_type" {
  description = "The compute type for the Docker Deploy project."
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "codebuild_image" {
  description = "The image that the Codebuild project will use."
  type        = string
  default     = "aws/codebuild/standard:5.0"
}

variable "codebuild_container_type" {
  description = "The type of container that the Codebuild project will use."
  type        = string
  default     = "LINUX_CONTAINER"
}

variable "codebuild_environment_variables" {
  description = "Optional environment variables that can be included in the Codebuild project."
  type        = list(
    object({
      name  = string
      value = string
    })
  )
  default = [
    {
      name  = "NO_ADDITIONAL_BUILD_VARS"
      value = "TRUE"
    }
  ]
}

variable "codebuild_vpc_id" {
  description = "The VPC ID for the Codebuild Project."
  type        = string
}

variable "codebuild_security_group_ids" {
  description = "The Security Group IDs for the Codebuild Project."
  type        = list(string)
}

variable "codebuild_vpc_subnets" {
  description = "The VPC Subnets for the Codebuild Project."
  type        = list(string)
}

# S3 Put Event & Lambda                ---------------------------------------------------------------------------------
variable "lambda_role" {
  description = "Role for the Lambda that triggers the Codebuild Project."
  type = string
}

variable "lambda_subnet_ids" {
  description = "The Subnet IDs for the Lambda that triggers the Codebuild Project."
  type = list(string)
}

variable "lambda_security_group_ids" {
  description = "The Security Group IDs for the Lambda that triggers the Codebuild Project."
  type = list(string)
}

