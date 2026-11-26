locals {
   ami_id = data.aws_ami.joindevops.id  
   sg_id = data.aws_ssm_parameter.sg_id.value
   private_subnet_ids = split(",",data.aws_ssm_parameter.private_subnet_ids.value)
   vpc_id = data.aws_ssm_parameter.vpc_id.value
   zone_name = data.aws_route53_zone.daws88s_zone.name
   backend_listener_arn = data.aws_ssm_parameter.backend_listener_arn.value
   frontend_listener_arn = data.aws_ssm_parameter.frontend_listener_arn.value
   health_check_path = var.components == frontend ? "/" : "/health"
   health_check_port = var.components == frontend ? "80" : "8080"
   host_header = var.components == frontend ? "${var.components}-${var.env}.${local.zone_name}" : "${var.components}.backend-alb-${var.env}.${local.zone_name}"
   target_group_arn = var.components == frontend ? local.frontend_listener_arn : local.backend_listener_arn
   common_tags = {
    project     = var.project
    environment = var.env
    terraform   = true
  }
}