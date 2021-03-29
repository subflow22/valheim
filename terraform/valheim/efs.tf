resource "aws_efs_file_system" "default" {
  creation_token = "${var.namespace}-${var.region}-efs"
  encrypted      = false

  tags = merge(
    var.tags,
    map(
      "Name", var.namespace
    )
  )
}

resource "aws_efs_mount_target" "default" {
  count           = length(var.pubnets) > length(var.az_names) ? length(var.az_names) : length(var.pubnets)
  file_system_id  = aws_efs_file_system.default.id
  subnet_id       = element(aws_subnet.public.*.id, count.index)
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "root" {
  file_system_id = aws_efs_file_system.default.id

  root_directory {
    path = "/"

    creation_info {
      owner_uid   = 0
      owner_gid   = 0
      permissions = 700
    }
  }
}

resource "aws_efs_access_point" "game" {
  file_system_id = aws_efs_file_system.default.id

  root_directory {
    path = "/steam_games/${var.namespace}"

    creation_info {
      owner_uid   = 1001
      owner_gid   = 1001
      permissions = 775
    }
  }
}
