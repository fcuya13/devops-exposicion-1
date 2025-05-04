output "web_instance_ids" {
  description = "IDs of the web instances"
  value       = aws_instance.ubuntu-vm-instance[*].id
}

output "web_private_ips" {
  description = "Private IPs of the web instances"
  value       = aws_instance.ubuntu-vm-instance[*].private_ip
}

output "api_gateway_url" {
  description = "URL of the API Gateway endpoint"
  value       = "${aws_api_gateway_stage.api_stage.invoke_url}${aws_api_gateway_resource.read_resource.path}"
}

output "ansible_control_public_ip" {
  description = "Public IP of the Ansible control node"
  value       = aws_instance.ansible_control.public_ip
}

output "load_balancer_url" {
  description = "URL of the Load Balancer"
  value       = aws_lb.app_lb.dns_name
}
