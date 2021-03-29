provider "aws" {
	region  = var.region
}

variable "region" {
	default = ""
}

variable "key" {
	default = ""
}

variable "namespace" {
	default = "valheim"
}

variable "vpc_cidr" {
	default = "10.1.0.0/24"
}

variable "pubnets" {
	type = list(string)
	default = [
		"10.1.0.0/27",
	]
}

variable "size" {
	default = "t3a.medium"
}

variable "domain" {
	default = "" # your dns domain, ie mydomain.me
}

variable "zone" {
	description = "public dns zone id"
	default     = ""
}

variable "game_data" {
	default = "/root/.config/unity3d/IronGate/Valheim/worlds"
}

variable "acl" {
	type = list
	default = [
		"", # your home ip, player ips, etc
	]
}

variable "app_id" {
	default = "896660"
}

variable "world_pass" {
	default = ""
}

variable "world_display" {
	default = ""
}

variable "world_name" {
	default = ""
}

variable "vol_type" {
	default = "gp2"
}

variable "vol_size" {
	default = "8"
}

variable "bucket_prefix" {
	default = "" # to make your bucket unique
}

locals {
    tags = map(
		"namespace", var.namespace,
    )
	bucket_name = "${var.bucket_prefix}-${var.region}-${var.namespace}"
}

data "aws_ami" "this" {
	most_recent = true

	owners = ["amazon"]

	filter {
		name   = "name"
		values = ["amzn2-ami-hvm-*-x86_64-ebs"]
	}

	filter {
		name   = "owner-alias"
		values = ["amazon"]
	}
}

data "aws_availability_zones" "available" {}

module ec2_steam {
	source 			= "../valheim"
	namespace 		= var.namespace
	region 			= var.region
	key				= var.key
	ami				= data.aws_ami.this.id
	size			= var.size
	domain			= var.domain
	zone			= var.zone
	acl				= var.acl
	pubnets			= var.pubnets
	az_names		= sort(data.aws_availability_zones.available.names)
	vpc_cidr		= var.vpc_cidr
	world_pass		= var.world_pass
	world_display	= var.world_display
	world_name		= var.world_name
	game_data		= var.game_data
	app_id			= var.app_id
	vol_size		= var.vol_size
	vol_type		= var.vol_type
	bucket_name		= local.bucket_name
	tags			= local.tags
	
}

output "ssh_connect" {
	value = module.valheim.ssh_connect
}

output "server_ip" {
	value = module.valheim.server_ip
}

output "vpc_id" {
	value = module.valheim.vpc_id
}

output "vpc_cidr" {
	value = module.valheim.vpc_cidr
}

output "subnet_ids" {
	value = module.valheim.subnet_ids
}