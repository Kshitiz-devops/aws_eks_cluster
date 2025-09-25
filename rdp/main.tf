provider "aws" {
  region = "us-east-1"
}

########################
# IAM Role for EC2
########################
resource "aws_iam_role" "jumpbox_role" {
  name = "windows-rdp-ssm-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.jumpbox_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allow EKS access (admin-level for demo)
resource "aws_iam_role_policy_attachment" "eks_admin" {
  role       = aws_iam_role.jumpbox_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_instance_profile" "jumpbox_profile" {
  name = "windows-rdp-ssm-eks-profile"
  role = aws_iam_role.jumpbox_role.name
}

########################
# Security Group
########################
resource "aws_security_group" "jumpbox_sg" {
  name        = "windows-rdp-jumpbox-sg"
  description = "RDP Jumpbox security group"
  vpc_id      = "vpc-xxxxxxxx" # replace with your VPC

  # RDP only inside VPC, not public
  ingress {
    description = "RDP inside VPC"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # adjust to your VPC CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################
# Private Subnet EC2 Instance
########################
resource "aws_instance" "jumpbox" {
  ami                    = "ami-0c1b2ca68f35f84f1" # Windows Server 2019 (check latest in region)
  instance_type          = "t3.medium"
  subnet_id              = "subnet-xxxxxxxx" # replace with private subnet
  vpc_security_group_ids = [aws_security_group.jumpbox_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.jumpbox_profile.name

  user_data = <<-EOF
    <powershell>
    # Install AWS CLI
    Invoke-WebRequest https://awscli.amazonaws.com/AWSCLIV2.msi -OutFile C:\\AWSCLIV2.msi
    Start-Process msiexec.exe -ArgumentList '/i C:\\AWSCLIV2.msi /quiet' -Wait

    # Install kubectl
    $KVersion = (Invoke-RestMethod -Uri https://dl.k8s.io/release/stable.txt)
    Invoke-WebRequest -Uri https://dl.k8s.io/$KVersion/bin/windows/amd64/kubectl.exe -OutFile C:\\Windows\\System32\\kubectl.exe
    </powershell>
  EOF

  tags = {
    Name = "Windows-RDP-Jumpbox-SSM-EKS"
  }
}

########################
# VPC Endpoints for SSM
########################
resource "aws_vpc_endpoint" "ssm" {
  vpc_id             = "vpc-xxxxxxxx"
  service_name       = "com.amazonaws.us-east-1.ssm"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = ["subnet-xxxxxxxx"] # private subnet(s)
  security_group_ids = [aws_security_group.jumpbox_sg.id]
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id             = "vpc-xxxxxxxx"
  service_name       = "com.amazonaws.us-east-1.ec2messages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = ["subnet-xxxxxxxx"]
  security_group_ids = [aws_security_group.jumpbox_sg.id]
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id             = "vpc-xxxxxxxx"
  service_name       = "com.amazonaws.us-east-1.ssmmessages"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = ["subnet-xxxxxxxx"]
  security_group_ids = [aws_security_group.jumpbox_sg.id]
}

########################
# Outputs
########################
output "jumpbox_instance_id" {
  value = aws_instance.jumpbox.id
}
