resource "aws_ecr_repository" "new_repo" {
  name                 = var.ecr_name
}

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-service-role"

  assume_role_policy = var.assume_policy_codebuild
}

resource "aws_iam_role_policy" "codebuild_role_policy" {
  role = aws_iam_role.codebuild_role.name

  policy = var.codebuild_role_policy
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = var.assume_policy_ecs_task
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  role = aws_iam_role.ecs_task_role.name

  policy = var.ecs_task_role_policy
}

resource "aws_codebuild_source_credential" "codebuild_creds" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_token
}

resource "aws_codebuild_project" "new_project" {
  name          = var.codebuild_project_name
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = var.docker_image
    type                        = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    type            = var.source_type
    location        = var.source_location
  }

  source_version = "master"
}

resource "aws_ecs_task_definition" "new_task" {
  family = "notejam-td"
  requires_compatibilities = ["FARGATE"]
  container_definitions = var.container_definitions_file
  execution_role_arn = aws_iam_role.ecs_task_role.arn
  network_mode = "awsvpc"
  cpu = 256
  memory = 512
}

resource "aws_ecs_cluster" "new_ecs_cluster" {
  name = var.ecs_cluster_name
  capacity_providers = ["FARGATE"]
}

resource "aws_security_group" "ecs_service_sg" {
  name        = "ecs-service-sg"
  description = "ECS Service Security Group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "new_ecs_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.new_ecs_cluster.id
  task_definition = aws_ecs_task_definition.new_task.arn
  desired_count   = 3
  launch_type = "FARGATE"

  network_configuration {
    subnets = var.private_subnets
    security_groups = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }
}

resource "aws_codepipeline" "codepipeline" {
  name     = "tf-test-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts  = ["source-output"]

      configuration = {
        ConnectionArn    = "arn:aws:codestar-connections:us-east-1:145476053377:connection/c5754338-cba2-4c98-8b47-83af3beb8d95"
        FullRepositoryId = "andreypindus/nodejam_container"
        FullRepositoryId = var.container_full_repoid
        BranchName       = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source-output"]

      configuration = {
        ProjectName = "notejam-build"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts  = ["source-output"]

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
        FileName = "imagedefinitions.json"
      }
    }
  }
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "codepipeline-notejam-bucket"
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "codestar-connections:UseConnection",
      "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": "iam:PassRole",
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": "ecs:*",
        "Resource": "*"
    }
  ]
}
EOF
}