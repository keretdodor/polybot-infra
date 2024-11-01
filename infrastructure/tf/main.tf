terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.55"
    }
  }

  required_version = ">= 1.7.0"

  backend "s3" {
    bucket = "dork-tf-state"
    key    = "tfstate.json"
    region = "eu-north-1"

  }

}
provider "aws" {
  region = var.aws_region
}

module "common" {
  source            = "./modules/common"
  sqs_queue_name    = "wowo-poly"
  dynamo_table_name = "polybot-table-s"
  bucket_name       = "becksboys-ganggang"

}

module "polybot" {
  source = "./modules/polybot"

  instance_type = "t3.micro"
  key_name      = "BECKS-stockholm-10/9/24"
  alias_record  = "polypol-ms.magvonim.site"
  vpc_id        = module.common.vpc_id
  subnet_id     = module.common.public_subnets
  cert_arn      = var.cert_arn


}
module "yolo5" {
  source = "./modules/yolo5"

  instance_type = "t3.micro"
  key_name      = "BECKS-stockholm-10/9/24"
  vpc_id        = module.common.vpc_id
  subnet_id     = module.common.public_subnets

  sqs_queue_url       = module.common.sqs_queue_url
  dynamodb_table_name = module.common.dynamodb_table_name
  s3_bucket           = module.common.bucket_name
  alias_record        = module.polybot.alias_record
  aws_region          = var.aws_region
  private_key         = var.private_key


}