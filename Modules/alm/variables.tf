variable "ecr_name" {
  description = "The name of the ECR repo"
}  

variable "assume_policy_codebuild" {
  default = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

variable "codebuild_role_policy" {
  default = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "logs:CreateLogStream",
                "codebuild:UpdateReport",
                "codebuild:BatchPutCodeCoverages",
                "logs:CreateLogGroup",
                "logs:PutLogEvents",
                "codebuild:BatchPutTestCases"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:list*",
                "s3:get*",
                "s3:put*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": "ecr:*",
            "Resource": "*"
        }
    ]
}
POLICY
}

variable "assume_policy_ecs_task" {
  default = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF  
}

variable "ecs_task_role_policy" {
  default = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "s3:get*",
                "s3:list*"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

variable "codebuild_project_name" {
  description = "The name of the project"
}

variable "docker_image" {
  description = "The docker image to use for the build"
}

variable "github_token" {
  description = "GitHub connection token"
  sensitive = true
}

variable "source_type" {
  description = "The type of the source"
}

variable "source_location" {
  description = "The location of the source"
}

variable "container_definitions_file" {
  description = "JSON file with container definition"
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
}

variable "ecs_service_name" {
  description = "The name of the ECS service"
}

variable "target_group_arn" {
  description = "The ARN of the ALB target group"
}

variable "container_name" {
  description = "The name of the container"
}

variable "container_port" {
  description = "Service port"
}

variable "private_subnets" {
  description = "ECS service subnets"
  type = list
}

variable "vpc_id" {
  description = "VPC where ECS security group will be created"
}

variable "container_full_repoid" {
  description = "The full app respository ID"
}