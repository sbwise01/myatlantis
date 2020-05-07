terraform {
  required_version = "~> 0.12.24"

  backend "s3" {
    bucket = "ryanthompson-fh-sandbox-tfstate"
    key    = "tfstate/atlantis/main.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region  = "us-west-2"
  version = "~> 2.45"
}

variable "cluster_name" {
  default = "atlantis"
}

variable "zones" {
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

module "vpc" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-vpc.git"

  name = "atlantis"
  cidr = "10.11.0.0/16"
  azs  = var.zones

  private_subnets = ["10.11.0.0/24", "10.11.1.0/24", "10.11.2.0/24"]
  public_subnets  = ["10.11.3.0/24", "10.11.4.0/24", "10.11.5.0/24"]

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }

  enable_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "poc"
  }
}

data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks.token
  load_config_file       = false
  version                = "1.11.1"
}

module "eks" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-eks.git?ref=v9.0.0"

  providers = {
    kubernetes = kubernetes.eks
  }

  manage_aws_auth = true
  cluster_name    = var.cluster_name
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id
  cluster_version = "1.15"
  map_roles       = []

  workers_additional_policies = []

  worker_groups = [
    {
      instance_type         = "t3.small"
      disk_size             = "5Gi"
      asg_desired_capacity  = 1
      asg_min_size          = 1
      asg_max_size          = 1
      autoscaling_enabled   = false
      protect_from_scale_in = false
    },
  ]
}

resource "aws_iam_user" "atlantis" {
  name = "atlantis"
}

resource "aws_iam_access_key" "atlantis" {
  user    = aws_iam_user.atlantis.name
  pgp_key = "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"
}

data "aws_iam_policy" "admin" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user_policy" "atlantis" {
  name = "admin"
  user = aws_iam_user.atlantis.name

  policy = data.aws_iam_policy.admin.policy
}

data "aws_route53_zone" "zone" {
  name         = "ryanthompson.fogops.io"
  private_zone = false
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "atlantis.ryanthompson.fogops.io"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  name    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.zone.zone_id
  records = [aws_acm_certificate.cert.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

output "cert_arn" {
  value = aws_acm_certificate.cert.arn
}

output "atlantis_creds" {
  value = aws_iam_access_key.atlantis
}
