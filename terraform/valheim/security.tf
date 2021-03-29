resource "aws_security_group" "default" {
	vpc_id   = aws_vpc.default.id
	name     = "${var.namespace}-server"

	ingress {
		from_port   = 22
		to_port     = 22
		protocol    = "tcp"
		cidr_blocks = var.acl
	}

	ingress {
		from_port   = 2456
		to_port     = 2458
		protocol    = "tcp"
		cidr_blocks = var.acl
	}
	
	ingress {
		from_port   = 27015
		to_port     = 27030
		protocol    = "tcp"
		cidr_blocks = var.acl
	}
	
	ingress {
		from_port   = 27036
		to_port     = 27037
		protocol    = "tcp"
		cidr_blocks = var.acl
	}
	
	ingress {
		from_port   = 2456
		to_port     = 2458
		protocol    = "udp"
		cidr_blocks = var.acl
	}

	ingress {
		from_port   = 4380
		to_port     = 4380
		protocol    = "udp"
		cidr_blocks = var.acl
	}
	
	ingress {
		from_port   = 27000
		to_port     = 27031
		protocol    = "udp"
		cidr_blocks = var.acl
	}
	
	ingress {
		from_port   = 27036
		to_port     = 27036
		protocol    = "udp"
		cidr_blocks = var.acl
	}

	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_security_group" "efs" {
	name    = "${var.namespace}-efs"
	vpc_id	= aws_vpc.default.id

	ingress {
		from_port   = 2049
		to_port     = 2049
		protocol    = "tcp"
		cidr_blocks = [aws_vpc.default.cidr_block]
	}
	
	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = [aws_vpc.default.cidr_block]
	}
}