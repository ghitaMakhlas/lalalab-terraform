provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAYZ2YHYSTYMKC4BGF"
  secret_key = "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"
}

# security group 
resource "aws_security_group" "lalalab-sg" {
  name        = "lalalab-sg"
  description = "lalalab security group"


  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#create a linux server 

resource "aws_instance" "lalalab-instance" {
  ami                    = "ami-038f1ca1bd58a5790"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.lalalab-sg.id]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.createkey.private_key_pem
    host        = aws_instance.lalalab-instance.public_ip
  }
  tags = {
    Name = "lalalab-instance"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install docker -y",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "sudo docker pull ghita88/lalalab-repository:latest",
      "sudo docker run -it -d -p 8085:8085 ghita88/lalalab-repository:latest",
      "sudo curl http://localhost:8085/rest/sayhello"
    ]
    
  }

}




#Creating key_pair for SSH in AWS instance

resource "tls_private_key" "createkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "aws_key_pair" "generated_key" {
  key_name   = "lalalab-key"
  public_key = tls_private_key.createkey.public_key_openssh
}

resource "null_resource" "savekey" {
  depends_on = [
    tls_private_key.createkey,
  ]
  provisioner "local-exec" {
    command = "echo  '${tls_private_key.createkey.private_key_pem}' > lalalab_key_pair.pem"
  }
}