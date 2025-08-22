# Define shared random suffix for unique resource naming
resource "random_id" "suffix" {
  byte_length = 2
}

module "cloudfront" {
  source = "./modules/cloudfront"

  distributions = {
    ui = {
      name                   = "${var.environment}-cf-fhir-ui"
      s3_bucket              = module.storage.buckets["ui"].bucket_regional_domain_name
      geo_restriction_type   = "whitelist"
      geo_locations          = ["US", "IN", "QA"]
      viewer_protocol_policy = "redirect-to-https"
      price_class            = "PriceClass_200"
      waf_enabled            = true
    }
    blockly = {
      name                   = "${var.environment}-cf-fhir-blockly"
      s3_bucket              = module.storage.buckets["blockly"].bucket_regional_domain_name
      geo_restriction_type   = "whitelist"
      geo_locations          = ["US", "IN", "QA"]
      viewer_protocol_policy = "redirect-to-https"
      price_class            = "PriceClass_All"
      waf_enabled            = false
    }
  }
}

module "storage" {
  source = "./modules/storage"
  s3_buckets = {
    ui            = { name = "${var.environment}-${random_id.suffix.hex}-s3-fhir-ui", policy_type = "cloudfront" }
    blockly       = { name = "${var.environment}-${random_id.suffix.hex}-s3-fhir-blockly", policy_type = "cloudfront" }
    api_artifacts = { name = "${var.environment}-${random_id.suffix.hex}-s3-fhir-api-artifacts", policy_type = "none" }
    public        = { name = "${var.environment}-${random_id.suffix.hex}-s3-public", policy_type = "public" }
  }
  cloudfront_distribution_arns = {
    ui      = module.cloudfront.distribution_arns["ui"]
    blockly = module.cloudfront.distribution_arns["blockly"]
  }
}

# Module for networking (VPC, subnets, etc.)
module "networking" {
  source               = "./modules/networking"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

  cluster_name = var.cluster_name
  environment  = var.environment
  tags = {
    Environment = var.environment
    Project     = "FHIR"
  }
}

# Module for IAM roles and policies
module "iam" {
  source      = "./modules/iam"
  environment = var.environment
}

# Module for RDS database
module "rds" {
  source               = "./modules/rds"
  db_subnet_group_name = module.networking.db_subnet_group_name
  rds_sg_id            = module.networking.rds_sg_id
  private_subnet_ids   = module.networking.private_subnet_ids
  vpc_id               = module.networking.vpc_id
  identifier           = "${var.environment}-rds-database-1"
  username             = "postgres"
  password             = var.rds_password
  db_password          = var.db_password
  rds_db_name          = var.rds_db_name
  instance_class       = "db.t3.micro"
  allocated_storage    = 50
  depends_on           = [module.networking]
}


# Module for EC2 instance
module "ec2" {
  source               = "./modules/ec2"
  ami                  = "ami-020cba7c55df1f615"
  instance_type        = "t3.medium"
  subnet_id            = module.networking.public_subnet_ids[0]
  security_group_ids   = [module.networking.ec2_sg_id]
  iam_instance_profile = module.iam.ec2_instance_profile_name
  rds_endpoint         = module.rds.rds_endpoint
  rds_port             = module.rds.rds_port
  rds_db_name          = module.rds.rds_db_name
  rds_username         = module.rds.rds_username
  rds_password         = module.rds.rds_password
  environment          = var.environment
  vpc_id               = module.networking.vpc_id
  depends_on           = [module.networking, module.iam, module.rds]
}

# Module for Lambda functions
module "lambda" {
  source            = "./modules/lambda"
  vpc_id            = module.networking.vpc_id
#  lambda_subnet_ids = module.networking.private_subnet_ids
#  lambda_sg_id      = module.networking.lambda_sg_id
  lambda_functions = {
    fhir_api_backend = {
      description = ""
      runtime     = "dotnet8"
      memory_size = 600
      timeout     = 300
      handler     = "FHIRServices.API::FHIRServices.API.LambdaEntryPoint::FunctionHandlerAsync"
      filename    = "fhir_api_handler.zip"
      role        = module.iam.lambda_role_arn
      environment_variables = {
        AWSRegion         = var.aws_region
        AccessKey         = var.aws_access_key
        SecretKey         = var.aws_secret_key
        BlocklyUrl        = "https://${module.cloudfront.distribution_domains["blockly"]}"
        BucketName        = module.storage.buckets["api_artifacts"].bucket
        FHIRResQueueURL   = module.sqs.queue_urls["BLOCKLY-REQUEST-VALIDATE"]
        FHIRReqQueueURL   = module.sqs.queue_urls["BLOCKLY-REQUEST-VALIDATE"]
        QueueURL          = module.sqs.queue_urls["BLOCKLY-TENANT-ID"]
        UserPoolClientId  = module.cognito.app_client_id
        UserPoolId        = module.cognito.user_pool_id
        ClientUrl         = "https://${module.cloudfront.distribution_domains["ui"]}"
        BaseUrl           = "http://${module.ec2.private_ip}:8082"
        LogGroupName      = "/aws/api/errorlogging"
#        DefaultConnection = "Host=localhost;Port=5432;Database=FHIRTest;Username=postgres;Password=core#NV17"
        PG_REMOTE_DB_HOST = module.rds.rds_endpoint
        PG_DATABASE       = module.rds.rds_db_name
        LogStreamName     = "api_errors"
        DefaultQuery      = "Patient?_count=50&_sort=-_lastUpdated"
        PG_USER           = module.rds.rds_username
        PG_PASSWORD       = module.rds.rds_password
        PG_PORT           = module.rds.rds_port
        PG_SSH_USER       = "ubuntu"
        PG_SSH_HOST       = module.ec2.public_ip
      }
    }
    #    fhir_converter = {
    #      description    = ""
    #      runtime        = "dotnet8"
    #      memory_size    = 256
    #      timeout        = 120
    #      handler        = "FHIRServices.Converter::FHIRServices.Converter.LambdaHandler::FunctionHandler"
    #      filename       = "./fhir_converter_handler.zip" #USE THE SAME NAME AND COPY THE FILE TO THE MODULE DIRECTORY
    #      role           = module.iam.lambda_role_arns["fhir_converter"]
    #      environment_variables = {}
    #    }
    #    scheduler_func = {
    #      description    = ""
    #      runtime        = "java21"
    #      memory_size    = 128
    #      timeout        = 300
    #      handler        = "LambdaFunctionHandler"
    #      filename       = "./scheduler.zip" # USE THE SAME NAME AND COPY THE FILE TO THE MODULE DIRECTORY
    #      role           = module.iam.lambda_role_arns["scheduler_func"]
    #      environment_variables = {
    #        DB_HOST     = ${module.rds.rds_endpoint}:${module.rds.rds_port}"
    #        DB_NAME     = "FHIR"
    #        DB_PASSWORD = "faDSF43qtqegfqjkaa4#"
    #        DB_USER     = "postgres"
    #      }
    #    }
  }
}

# Module for API Gateway
module "api_gateway" {
  source                 = "./modules/api_gateway"
  rest_api_name          = "${var.environment}-fhir-api-gateway"
  api_name               = "${var.environment}-fhir-api"
  lambda_function_name   = module.lambda.aws_lambda_function["fhir_api_backend"].function_name
  lambda_integration_uri = module.lambda.aws_lambda_function["fhir_api_backend"].arn
  aws_region             = var.aws_region
}

# Module for Cognito user pool and identity pool
module "cognito" {
  source              = "./modules/cognito"
  pool_name           = "FHIR_BLOCKLY"
  domain_prefix       = "blockly-${var.environment}-${random_id.suffix.hex}"
  app_client_name     = "FHIR"
  app_callback_urls   = ["https://callback"]
  deletion_protection = false
  aws_region          = var.aws_region
}

module "eks_cluster" {
  source                          = "./modules/eks"
  aws_region                      = var.aws_region
  cluster_name                    = "fhir-nifi-cluster"
  eks_version                     = "1.32"
  vpc_id                          = module.networking.vpc_id
  subnet_ids                      = module.networking.private_subnet_ids
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  eks_node_ami_type               = "AL2_x86_64"
  eks_node_instance_types         = ["t3.medium"]
  eks_node_capacity_type          = "ON_DEMAND"
  authentication_mode             = "API_AND_CONFIG_MAP"
  eks_node_min_size               = 1
  eks_node_max_size               = 3
  eks_node_desired_size           = 2
  ebs_csi_addon_version           = "v1.44.0-eksbuild.1"
  devops_user_arn                 = "arn:aws:iam::541448617660:user/amalfhir"
  root_account_arn                = "arn:aws:iam::541448617660:root"
  gitlab_pat                      = var.gitlab_pat


  tags = {
    Environment = "dev"
    Project     = "fhir"
  }
  depends_on = [module.networking]
}

# Load Balancer Controller IAM Role (IRSA)
module "lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"
  role_name                              = "${module.eks_cluster.cluster_name}-lb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks_cluster.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Environment = "dev"
    Project     = "fhir"
  }
  depends_on = [module.eks_cluster]
}

# Module for SQS queues
module "sqs" {
  source        = "./modules/sqs"
  queue_configs = var.queue_configs
  common_tags   = var.common_tags
}
