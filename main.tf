resource "aws_instance" "main" {
  ami           = local.ami_id
  instance_type = var.instance_type
  subnet_id = local.private_subnet_ids[0]
  vpc_security_group_ids = [ local.sg_id ]
  tags = merge(var.tags, {Name = "${var.project}-${var.env}-${var.components}"}, local.common_tags)

 
}

resource "terraform_data" "main_bootstrap" {
   triggers_replace = [ aws_instance.main.id ]

   connection {
      type = "ssh"
      user = "ec2-user"
      host = aws_instance.main.private_ip
      password = "DevOps321"
   }

   provisioner "file" {
     source = "bootstrap.sh"
     destination = "/tmp/bootstrap.sh"
   }

   provisioner "remote-exec" {
      inline = [ 
            "chmod +x /tmp/bootstrap.sh",
            "sudo sh /tmp/bootstrap.sh ${var.components} ${var.env} ${var.app_version}"
       ]
   }
}

resource "aws_ec2_instance_state" "main" {
   instance_id = aws_instance.main.id
   state = "stopped"

   depends_on = [ terraform_data.main_bootstrap ]
}

resource "aws_ami_from_instance" "main" {
    name = "${var.project}-${var.env}-${var.components}"
    source_instance_id = aws_instance.main.id

    depends_on = [ aws_ec2_instance_state.main ]
}



resource "aws_lb_target_group" "main" {
  name        = "${var.project}-${var.env}-${var.components}"
  target_type = "instance"
  port = var.components == "frontend" ? 80 : 8080
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  health_check {
    enabled = true
    port = local.health_check_port
    protocol = "HTTP"
    path = local.health_check_path
    healthy_threshold = 2 
    unhealthy_threshold = 2
    interval = 10
    timeout = 2
    matcher = "200-299"
  }
}


resource "aws_launch_template" "main" {
  name = "${var.project}-${var.env}-${var.components}"
  image_id = aws_ami_from_instance.main.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [local.sg_id]
  update_default_version = true 
  instance_initiated_shutdown_behavior = "terminate"
  tag_specifications {
    resource_type = "instance"

    tags = merge( {Name = "${var.project}-${var.env}-${var.components}"} , local.common_tags)

  }

  tag_specifications {
    resource_type = "volume"

    tags = merge( {Name = "${var.project}-${var.env}-${var.components}"} , local.common_tags)

  }

  tags = merge( {Name = "${var.project}-${var.env}-${var.components}"} , local.common_tags)
}


resource "aws_autoscaling_group" "main" {
  
  name = "${var.project}-${var.env}-${var.components}"
  vpc_zone_identifier = local.private_subnet_ids
  health_check_type = "ELB"
  health_check_grace_period = 120
  desired_capacity   = 2
  max_size           = 10
  min_size           = 2
   instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }

  timeouts {
    delete = "15m"
  }

  launch_template {
    id      = aws_launch_template.main.id
    version = aws_launch_template.main.latest_version
  }
  target_group_arns = [ aws_lb_target_group.main.arn ]

 

  dynamic "tag" {
     for_each = merge({Name = "${var.project}-${var.env}-${var.components}"} , local.common_tags)

     content {
        key = tag.key
        value = tag.value 
        propagate_at_launch = true
     }
  }
}



resource "aws_autoscaling_policy" "main" {
  autoscaling_group_name = aws_autoscaling_group.main.name
  name                   = "${var.project}-${var.env}-${var.components}"
  policy_type            = "TargetTrackingScaling"
  estimated_instance_warmup = 120 
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
      target_value = 70.0
    }
  }
  

  resource "aws_alb_listener_rule" "main" {
    priority = var.rule_priority
    listener_arn =  local.listener_arn
    action {
       type = "forward"
       target_group_arn = aws_lb_target_group.main.arn
    }
    condition {
       host_header {
          values = [local.host_header]
       }
    }
  }

  # resource "terraform_data" "main_delete" {
  #    depends_on = [ aws_autoscaling_policy.main ]
  #    triggers_replace = [ aws_instance.main.id ]

  #    provisioner "local-exec" {
  #        command = "aws ec2 terminate-instances --instance-ids ${aws_instance.main.id}"
  #    }
  # }