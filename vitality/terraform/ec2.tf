data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "airflow_sg" {
  name        = "${var.project_name}-${var.environment}-airflow-sg"
  description = "Restricts Airflow Webserver access to corporate VPN CIDRs"

  ingress {
    description = "Airflow Web UI over VPN"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.airflow_allowed_cidr_blocks
  }

  egress {
    description = "Outbound HTTPS to AWS APIs, S3, and Redshift Serverless"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "airflow_host" {
  ami                    = data.aws_ami.ubuntu_2204.id
  instance_type          = var.airflow_instance_type
  iam_instance_profile   = aws_iam_instance_profile.airflow_ec2_profile.name
  vpc_security_group_ids = [aws_security_group.airflow_sg.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Enforce IMDSv2
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              set -euxo pipefail
              apt-get update -y
              apt-get install -y docker.io docker-compose-v2 git
              systemctl enable --now docker
              EOF

  tags = {
    Name                 = "${var.project_name}-${var.environment}-airflow-orchestrator"
    AutoSchedule         = "true"
    ScheduleWindow       = "00:45-04:00-UTC"
  }
}
