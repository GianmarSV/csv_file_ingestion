resource "aws_db_subnet_group" "main" {
  name       = "main-subnet-group"
  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name = "main-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "16.2"
  instance_class       = "db.t3.micro"
  #name                 = "csvdb"
  username             = "engineer"
  password             = "password_tech"
  #parameter_group_name = "default.postgres12"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.main.name
  publicly_accessible  = true

  vpc_security_group_ids = [aws_security_group.rds.id]

  #tags = {
  #  Name = "postgres-instance"
  #}
}

resource "aws_security_group" "rds" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}