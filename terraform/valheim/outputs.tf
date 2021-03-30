output "ssh_connect" {
  value = "ssh -i ${var.key}.pem ec2-user@${aws_route53_record.default.name}"
}

output "server_ip" {
  value = aws_instance.default.public_ip
}

output "vpc_id" {
  value = aws_vpc.default.id
}

output "vpc_cidr" {
  value = aws_vpc.default.cidr_block
}

output "subnet_ids" {
  value = data.aws_subnet_ids.ids
}