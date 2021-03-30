data "template_file" "valheim_backup_ssm" {
  template = file("${path.module}/files/valheim_backup.yml.tpl")

  vars = {
    BUCKET_NAME = aws_s3_bucket.default.id
  }

  depends_on = [
    aws_instance.default
  ]
}

resource "aws_ssm_document" "valheim_backup" {
  name            = "${var.namespace}-valheim-backup"
  document_type   = "Command"
  document_format = "YAML"
  target_type     = "/AWS::EC2::Instance"

  content = data.template_file.valheim_backup_ssm.rendered

  depends_on = [
    aws_instance.default
  ]
}

resource "aws_ssm_association" "valheim_backup" {
  association_name            = "${var.namespace}-valheim-backup"
  name                        = aws_ssm_document.valheim_backup.name
  schedule_expression         = "cron(0 3 * * ? *)"
  apply_only_at_cron_interval = "true"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.default.id]
  }

  output_location {
    s3_bucket_name = aws_s3_bucket.default.id
    s3_key_prefix  = "backups/"
  }

  depends_on = [
    aws_instance.default
  ]
}


