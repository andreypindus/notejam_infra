provider "aws" {
  region = "us-east-1"
}

module "create_vpc" {
  source               = "../Modules/create_vpc"
  cidr_block           = "10.0.0.0/16"
  vpc_name             = "main_vpc"
  enable_dns_hostnames = true

  # Subnet AZs
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # Create public subnets
  public_subnets      = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
  public_subnet_names = ["public_subnet-1","public_subnet-2","public_subnet-3"]

  # Create private subnets
  private_subnets      = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  private_subnet_names = ["private_subnet-1", "private_subnet-2", "private_subnet-3"]

  # Create internet Gateway (Only if at least one public subnet is created)
  internet_gateway_name = "main_vpc_gateway"
}

module "iam_role" {
  source        = "../Modules/iam_role"
  role_name     = "rds_role"
  assume_policy = var.assume_policy
  role_policy   = var.role_policy
}


module "aws_rds" {
  source            = "../Modules/aws_rds"
  engine            = "postgres"
  engine_version    = "10.3"
  instance_class    = "db.t2.micro"
  allocated_storage = 16
  storage_type      = "gp2"
  storage_encrypted = false
  identifier        = "maindb"

  #This is the DB Name
  name       = "notejamdb"
  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  username = var.username
  password = var.password
  port     = "5432"

  vpc_id       = module.create_vpc.new_vpc_id
  private_cidr = [module.create_vpc.vpc_cidr]

  # DB subnet group
  subnet_ids = module.create_vpc.private_subnet_id

  # DB parameter group
  family = "postgres10"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "rds-postgresql"
}

module "aws_alb" {
  source = "../Modules/aws_alb"

  # SG creation  
  group_name = "alb_group"
  vpc_id = module.create_vpc.new_vpc_id
  
  # ALB
  name = "notejam-alb"
  subnets = module.create_vpc.public_subnet_id


  # Target group
  tg_name = "notejam-tg"
  tg_port = 80
  tg_protocol = "HTTP"
}

data "template_file" "container-definition" {
    template = file("task-definitions/service.tpl")

    vars = {
      app_db_host = module.aws_rds.db_host
      app_db_port = module.aws_rds.db_port
      app_db_user = var.username
      app_db_pass = var.password
    }
}

module "alm" {
  source = "../Modules/alm"

  vpc_id = module.create_vpc.new_vpc_id
  ecr_name = "notejam"
  codebuild_project_name = "notejam-build"
  docker_image = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
  source_type = "GITHUB"
  source_location = "https://github.com/andreypindus/nodejam_container.git"
  github_token = var.github_token
  container_definitions_file = data.template_file.container-definition.rendered
  ecs_cluster_name = "notejam-cluster"
  ecs_service_name = "notejam-service"
  target_group_arn = module.aws_alb.alb_target_id
  container_name = "notejam-container"
  container_port = "80"
  private_subnets = module.create_vpc.private_subnet_id
  container_full_repoid = "andreypindus/nodejam_container"
}