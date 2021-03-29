terraform {

	backend "s3" {
		encrypt        = true
		region         = ""
		bucket         = ""
		dynamodb_table = ""
		key            = ""
	}
}