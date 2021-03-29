resource "aws_s3_bucket" "default" {
    bucket = var.bucket_name
	acl    = "private"

	server_side_encryption_configuration {
		rule {
			apply_server_side_encryption_by_default {
				sse_algorithm     = "aws:kms"
			}
		}
	}

	tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "default" {
	bucket 					= aws_s3_bucket.default.id
	block_public_acls   	= true
	block_public_policy 	= true
	ignore_public_acls		= true
	restrict_public_buckets = true
  
}

resource "aws_s3_access_point" "default" {
	name   	= aws_s3_bucket.default.id
	bucket 	= aws_s3_bucket.default.id
	policy	= data.aws_iam_policy_document.ssm_s3_accesspoint.json
	
	vpc_configuration {
		vpc_id =	aws_vpc.default.id
	}

	public_access_block_configuration {
		block_public_acls       = true
		block_public_policy     = true
		ignore_public_acls      = true
		restrict_public_buckets = true
	}
	
	depends_on = [
		aws_s3_bucket.default,
	]
}

