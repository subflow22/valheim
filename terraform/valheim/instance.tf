data "template_file" "cloudwatch" {

    template	= file("${path.module}/files/cloudwatch.json.tpl")

	vars = {
		NAMESPACE			= var.namespace
		REGION				= var.region
		IID					= "$${aws:ImageId}"
		IND					= "$${aws:InstanceId}"
		IST					= "$${aws:InstanceType}"
		ASG					= "$${aws:AutoScalingGroupName}"
		GAME_DATA			= var.game_data
		LOG_GROUP			= aws_cloudwatch_log_group.default.name
	}
}

data "template_file" "init" {

	template	= file("${path.module}/files/init.sh.tpl")
	
	vars = {
		NAMESPACE 		= var.namespace
		EFS_AP    		= aws_efs_access_point.game.id
		EFS_ID    		= aws_efs_file_system.default.id
		GAME_DATA	    = var.game_data
		WORLD_PASS		= var.world_pass
		WORLD_DISPLAY	= var.world_display
		WORLD_NAME		= var.world_name
		APP_ID			= var.app_id
		BUCKET_NAME		= aws_s3_bucket.default.id
		LOG_GROUP		= aws_cloudwatch_log_group.default.name
		TEMPLATE_FILE	= data.template_file.cloudwatch.rendered
	}
	
	depends_on = [
		data.template_file.cloudwatch
	]
}

resource "aws_instance" "default" {
	ami                    = var.ami
	instance_type          = var.size
	key_name               = var.key
	subnet_id              = element(aws_subnet.public.*.id, 0)
	vpc_security_group_ids = [aws_security_group.default.id]
	
	root_block_device {
		volume_size				= var.vol_size
		volume_type				= var.vol_type
		delete_on_termination 	= true
	}
  
	tags = {
		Name      = "ec2-${var.namespace}"
		namespace = var.namespace
	}

	iam_instance_profile	= aws_iam_instance_profile.default.id
	user_data				= data.template_file.init.rendered
	
	lifecycle {
		ignore_changes = [user_data]
	}
}