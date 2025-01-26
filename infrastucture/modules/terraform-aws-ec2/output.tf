output "private_key_pem" {
  value     = tls_private_key.generated_key.private_key_pem
  sensitive = true
}

output "instance_public_ip" {
  value       = aws_instance.instance.public_ip
  description = "Public IP address of the EC2 instance"
}

output "instance_id" {
  value = aws_instance.instance.id
}
