module activegate_ec2 {
  source = "../modules/terraform-aws-ec2"

  vpc_name = "o11y-lab-vpc"
  public_subnet_name = "o11y-lab-public-subnet"
  igw_name = "o11y-lab-igw"
  route_table_name = "o11y-lab-public-route-table"
  security_group_name = "o11y-lab-sg"
  instance_name = "DynatraceActiveGate"
  role_name = module.activegate_monitoring_role.active_gate_role_name
}

module activegate_monitoring_role {
  source = "../modules/terraform-aws-dynatrace-activegate-monitoring-role"

  active_gate_role_name = "dynatrace_ag_role_name"
  assume_policy_name    = "dynatrace_assume_policy"
  monitoring_role_name  = "dynatrace_monitoring_role"
  monitored_account_id  = var.monitored_account_id
}

module terraform-aws-dynatrace-monitoring-role {
  source = "../modules/terraform-aws-dynatrace-monitoring-role"
  external_id           = var.external_id
  active_gate_role_name = module.activegate_monitoring_role.active_gate_role_name
  active_gate_account_id = var.monitored_account_id
}

output "monitoring_role" {
  value = module.activegate_monitoring_role.monitoring_role_name
}

output "private_key_pem" {
  value     = module.activegate_ec2.private_key_pem
  sensitive = true
}

output "instance_public_ip" {
  value       = module.activegate_ec2.instance_public_ip
  description = "Public IP address of the EC2 instance"
}

variable "DYNATRACE_ACTIVEGATE_TOKEN" {
  description = "API token for Dynatrace ActiveGate installation"
  type        = string
  # sensitive   = true
}

variable "DYNATRACE_ENV_URL" {
  description = ""
  type        = string
  # sensitive   = true
}

resource "null_resource" "install_activegate" {
  triggers = {
    instance_id = module.activegate_ec2.instance_id
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = module.activegate_ec2.instance_public_ip
      user        = "ec2-user"
      private_key = module.activegate_ec2.private_key_pem
    }

    inline = [
      "sudo dnf install libxcrypt-compat -y",
      "wget -O Dynatrace-ActiveGate-Linux-x86-1.305.57.sh \"${var.DYNATRACE_ENV_URL}\" --header=\"Authorization: Api-Token ${var.DYNATRACE_ACTIVEGATE_TOKEN}\"",
      "wget https://ca.dynatrace.com/dt-root.cert.pem",
      "( echo 'Content-Type: multipart/signed; protocol=\"application/x-pkcs7-signature\"; micalg=\"sha-256\"; boundary=\"--SIGNED-INSTALLER\"'; echo ; echo ; echo '----SIGNED-INSTALLER' ; cat Dynatrace-ActiveGate-Linux-x86-1.305.57.sh ) | openssl cms -verify -CAfile dt-root.cert.pem > /dev/null",
      "sudo /bin/bash Dynatrace-ActiveGate-Linux-x86-1.305.57.sh",
    ]
  }

  depends_on = [module.activegate_ec2]
}

########################################################################################
# PAMIĘTA O DODANIU ROLI DO EC2
########################################################################################
