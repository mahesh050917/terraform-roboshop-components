locals {
   ami_id = data.aws_ami.joindevops.id  
   sg_id = data.aws_ssm_parameter.sg_id.value
   private_subnet_ids = split(",",data.aws_ssm_parameter.private_subnet_ids.value)
   vpc_id = data.aws_ssm_parameter.vpc_id.value
   zone_name = data.aws_route53_zone.daws88s_zone.name
   backend_listener_arn = data.aws_ssm_parameter.backend_listener_arn.value
   common_tags = {
    project     = var.project
    environment = var.env
    terraform   = true
  }
}