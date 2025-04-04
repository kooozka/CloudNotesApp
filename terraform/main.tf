terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Zmienne pomocnicze dla rozwiązania cyklicznych zależności
locals {
  # Szablony URL dla serwerów
  backend_url = "http://266537-notes-app-backend.${var.region}.elasticbeanstalk.com"
  frontend_url = "http://266537-notes-app-frontend.${var.region}.elasticbeanstalk.com"
  # URL HTTPS przez API Gateway - używamy hardcoded wartości aby uniknąć cyklicznej referencji
  frontend_url_https = "https://api-gateway-id.execute-api.${var.region}.amazonaws.com/prod"
}

# Amazon Cognito - User Pool
resource "aws_cognito_user_pool" "notes_user_pool" {
  name = "notes-app-user-pool"
  
  # Ustawienia walidacji hasła
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }
  
  # Ustawienia auto-weryfikacji
  auto_verified_attributes = ["email"]
  
  # Usunięto definicję schematu, która powodowała błąd
  
  # Ustawienia wysyłania wiadomości
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
  
  # Konfiguracja weryfikacji konta
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject = "Potwierdź swoje konto"
    email_message = "Twój kod weryfikacyjny to {####}."
  }
  
  # Zapobiega niszczeniu i ponownemu tworzeniu zasobu
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      schema
    ]
  }
}

# Amazon Cognito - User Pool Client dla aplikacji React
resource "aws_cognito_user_pool_client" "notes_client" {
  name                         = "notes-app-client"
  user_pool_id                 = aws_cognito_user_pool.notes_user_pool.id
  generate_secret              = false
  refresh_token_validity       = 30
  access_token_validity        = 1
  id_token_validity            = 1
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]
  # Używamy lokalnych zmiennych zamiast referencji do zasobów
  callback_urls        = ["https://localhost:3000", local.frontend_url_https]
  logout_urls          = ["https://localhost:3000", local.frontend_url_https]
  allowed_oauth_flows  = ["implicit", "code"]
  allowed_oauth_scopes = ["email", "openid", "profile"]
  supported_identity_providers = ["COGNITO"]
}

# Amazon Cognito - User Pool Domain
resource "aws_cognito_user_pool_domain" "notes_domain" {
  domain       = "notes-app-${random_string.suffix.result}"
  user_pool_id = aws_cognito_user_pool.notes_user_pool.id
}

provider "aws" {
  region = "us-east-1" # Zmieniono na us-east-1 dla konta AWS Learners
}

# Zmienne wejściowe
variable "region" {
  description = "The AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "db_username" {
  description = "Username for the RDS database"
  type        = string
  default     = "notesapp_user"
}

variable "db_password" {
  description = "Password for the RDS database"
  type        = string
  default     = "notes123"  # W środowisku produkcyjnym używaj secrets
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = "notes-app-deployment-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 bucket na załączniki notatek
resource "aws_s3_bucket" "notes_attachments" {
  bucket = "notes-app-attachments-${random_string.suffix.result}"
}

# Konfiguracja publicznego dostępu do S3 dla załączników
resource "aws_s3_bucket_public_access_block" "notes_attachments_public_access" {
  bucket = aws_s3_bucket.notes_attachments.id
  
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.notes_attachments.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.notes_attachments.arn}/*"
      }
    ]
  })
}

# Definicja VPC
resource "aws_vpc" "notes_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "notes-app-vpc"
  }
}

# Publiczne podsieci (dla Elastic Beanstalk)
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.notes_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"  # Zmieniono na strefę dostępności w regionie us-east-1
  map_public_ip_on_launch = true

  tags = {
    Name = "notes-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.notes_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"  # Zmieniono na strefę dostępności w regionie us-east-1
  map_public_ip_on_launch = true

  tags = {
    Name = "notes-public-subnet-2"
  }
}

# Prywatne podsieci (dla RDS)
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.notes_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"  # Zmieniono na strefę dostępności w regionie us-east-1

  tags = {
    Name = "notes-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.notes_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"  # Zmieniono na strefę dostępności w regionie us-east-1

  tags = {
    Name = "notes-private-subnet-2"
  }
}

# Internet Gateway dla ruchu wychodzącego z publicznych podsieci
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.notes_vpc.id

  tags = {
    Name = "notes-app-igw"
  }
}

# Elastic IP dla NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true
  
  tags = {
    Name = "notes-app-nat-eip"
  }
}

# NAT Gateway dla ruchu wychodzącego z prywatnych podsieci
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "notes-app-nat-gw"
  }
  
  depends_on = [aws_internet_gateway.igw]
}

# Tabela routingu dla publicznych podsieci
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.notes_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "notes-app-public-rt"
  }
}

# Tabela routingu dla prywatnych podsieci
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.notes_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "notes-app-private-rt"
  }
}

# Powiązanie tabel routingu z podsieciami
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# Grupy bezpieczeństwa
resource "aws_security_group" "backend_sg" {
  name        = "notes-backend-sg"
  description = "Security group for backend application"
  vpc_id      = aws_vpc.notes_vpc.id

  # Pozwól na cały ruch wychodzący
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Pozwól na ruch HTTP/HTTPS
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Pozwól na ruch do Spring Boot
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "notes-backend-sg"
  }
}

resource "aws_security_group" "frontend_sg" {
  name        = "notes-frontend-sg"
  description = "Security group for frontend application"
  vpc_id      = aws_vpc.notes_vpc.id

  # Pozwól na cały ruch wychodzący
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Pozwól na ruch HTTP/HTTPS
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "notes-frontend-sg"
  }
}

# Grupa zabezpieczeń dla RDS (tylko dostęp z backendu)
resource "aws_security_group" "rds_sg" {
  name        = "notes-rds-sg"
  description = "Allow database traffic from Elastic Beanstalk backend"
  vpc_id      = aws_vpc.notes_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "notes-rds-sg"
  }
}

# Grupa podsieci dla RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "notes-rds-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "notes-rds-subnet-group"
  }
}

# Przygotowanie zipów aplikacji dla Elastic Beanstalk
resource "aws_s3_object" "frontend_zip" {
  bucket = aws_s3_bucket.app_bucket.id
  key    = "frontend-app.zip"
  source = "../frontend-app.zip"  # Zakładamy, że zip został przygotowany
  etag   = filemd5("../frontend-app.zip")
}

resource "aws_s3_object" "backend_zip" {
  bucket = aws_s3_bucket.app_bucket.id
  key    = "backend-app.zip"
  source = "../backend-app.zip"  # Zakładamy, że zip został przygotowany
  etag   = filemd5("../backend-app.zip")
}

# Aplikacje Elastic Beanstalk
resource "aws_elastic_beanstalk_application" "frontend" {
  name        = "notes-frontend-app"
  description = "Notes App Frontend"
}

resource "aws_elastic_beanstalk_application" "backend" {
  name        = "notes-backend-app"
  description = "Notes App Backend"
}

# Wersje aplikacji
resource "aws_elastic_beanstalk_application_version" "frontend_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.frontend.name
  bucket      = aws_s3_bucket.app_bucket.id
  key         = aws_s3_object.frontend_zip.id
}

resource "aws_elastic_beanstalk_application_version" "backend_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.backend.name
  bucket      = aws_s3_bucket.app_bucket.id
  key         = aws_s3_object.backend_zip.id
}

# Środowisko dla frontendu
resource "aws_elastic_beanstalk_environment" "frontend_env" {
  name                = "notes-frontend-env"
  application         = aws_elastic_beanstalk_application.frontend.name
  solution_stack_name = "64bit Amazon Linux 2 v4.0.8 running Docker"
  version_label       = aws_elastic_beanstalk_application_version.frontend_version.name
  cname_prefix        = "266537-notes-app-frontend"

  # Konfiguracja VPC
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.notes_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.public_subnet_1.id},${aws_subnet.public_subnet_2.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.public_subnet_1.id},${aws_subnet.public_subnet_2.id}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.frontend_sg.id
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "LabInstanceProfile"  # Profil IAM dla konta AWS Learners
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
  
  # Zmienne środowiskowe
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REACT_APP_API_URL"
    value     = local.backend_url
  }

  # Zmienne środowiskowe dla Amazon Cognito - frontend
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REACT_APP_AWS_REGION"
    value     = "us-east-1"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REACT_APP_USER_POOL_ID"
    value     = aws_cognito_user_pool.notes_user_pool.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REACT_APP_USER_POOL_CLIENT_ID"
    value     = aws_cognito_user_pool_client.notes_client.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REACT_APP_COGNITO_DOMAIN"
    value     = "${aws_cognito_user_pool_domain.notes_domain.domain}.auth.${var.region}.amazoncognito.com"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REACT_APP_REDIRECT_SIGN_IN"
    value     = local.frontend_url_https
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REACT_APP_REDIRECT_SIGN_OUT"
    value     = local.frontend_url_https
  }
}

# Środowisko dla backendu
resource "aws_elastic_beanstalk_environment" "backend_env" {
  name                = "notes-backend-env"
  application         = aws_elastic_beanstalk_application.backend.name
  solution_stack_name = "64bit Amazon Linux 2 v4.0.8 running Docker"
  version_label       = aws_elastic_beanstalk_application_version.backend_version.name
  cname_prefix        = "266537-notes-app-backend"

  # Konfiguracja VPC
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.notes_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.public_subnet_1.id},${aws_subnet.public_subnet_2.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.public_subnet_1.id},${aws_subnet.public_subnet_2.id}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.backend_sg.id
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "LabInstanceProfile"  # Profil IAM dla konta AWS Learners
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  # Zmienne środowiskowe dla backendu
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SPRING_DATASOURCE_URL"
    value     = "jdbc:postgresql://${aws_db_instance.notes_db.endpoint}/${aws_db_instance.notes_db.db_name}?stringtype=unspecified"
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SPRING_DATASOURCE_USERNAME"
    value     = var.db_username
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SPRING_DATASOURCE_PASSWORD"
    value     = var.db_password
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SPRING_JPA_HIBERNATE_DDL_AUTO"
    value     = "update"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_S3_BUCKET_NAME"
    value     = aws_s3_bucket.notes_attachments.bucket
  }
  
  # Zmienne środowiskowe dla Cognito - backend
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "COGNITO_ISSUER_URI"
    value     = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.notes_user_pool.id}"
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "COGNITO_AUDIENCE"
    value     = aws_cognito_user_pool_client.notes_client.id
  }
}

# Baza danych RDS PostgreSQL
resource "aws_db_instance" "notes_db" {
  identifier             = "notes-app-db"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "17.2"  # Stabilna wersja PostgreSQL
  instance_class         = "db.t3.micro"
  db_name                = "notesdb"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.postgres17"
  publicly_accessible    = false
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name

  tags = {
    Name = "notes-app-database"
  }
}

# Outputs
output "frontend_url" {
  value = aws_elastic_beanstalk_environment.frontend_env.cname
}

output "backend_url" {
  value = aws_elastic_beanstalk_environment.backend_env.cname
}

output "database_endpoint" {
  value = aws_db_instance.notes_db.endpoint
}

output "attachment_bucket" {
  value = aws_s3_bucket.notes_attachments.bucket
}

output "cognito_user_pool_id" {
  value       = aws_cognito_user_pool.notes_user_pool.id
  description = "ID puli użytkowników Amazon Cognito"
}

output "cognito_client_id" {
  value       = aws_cognito_user_pool_client.notes_client.id
  description = "ID klienta Amazon Cognito"
}

output "cognito_domain" {
  value       = "${aws_cognito_user_pool_domain.notes_domain.domain}.auth.${var.region}.amazoncognito.com"
  description = "Domena Amazon Cognito"
}

output "api_gateway_https_url" {
  value       = "${aws_api_gateway_deployment.frontend_deployment.invoke_url}"
  description = "HTTPS URL z API Gateway dla frontendu"
}

# API Gateway jako HTTPS proxy dla frontendu
resource "aws_api_gateway_rest_api" "frontend_proxy" {
  name        = "notes-frontend-proxy"
  description = "HTTPS proxy for Notes frontend app"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Zasób proxy do przekazywania wszystkich żądań
resource "aws_api_gateway_resource" "proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.frontend_proxy.id
  parent_id   = aws_api_gateway_rest_api.frontend_proxy.root_resource_id
  path_part   = "{proxy+}"
}

# Metoda ANY dla obsługi wszystkich metod HTTP
resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.frontend_proxy.id
  resource_id   = aws_api_gateway_resource.proxy_resource.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# Integracja HTTP dla przekazywania żądań do frontendu
resource "aws_api_gateway_integration" "frontend_integration" {
  rest_api_id = aws_api_gateway_rest_api.frontend_proxy.id
  resource_id = aws_api_gateway_resource.proxy_resource.id
  http_method = aws_api_gateway_method.proxy_method.http_method
  
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_elastic_beanstalk_environment.frontend_env.cname}/{proxy}"
  
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

# Obsługa metody na ścieżce głównej
resource "aws_api_gateway_method" "root_method" {
  rest_api_id   = aws_api_gateway_rest_api.frontend_proxy.id
  resource_id   = aws_api_gateway_rest_api.frontend_proxy.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_integration" {
  rest_api_id = aws_api_gateway_rest_api.frontend_proxy.id
  resource_id = aws_api_gateway_rest_api.frontend_proxy.root_resource_id
  http_method = aws_api_gateway_method.root_method.http_method
  
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_elastic_beanstalk_environment.frontend_env.cname}"
}

# Wdrożenie API Gateway
resource "aws_api_gateway_deployment" "frontend_deployment" {
  depends_on = [
    aws_api_gateway_integration.frontend_integration,
    aws_api_gateway_integration.root_integration
  ]
  
  rest_api_id = aws_api_gateway_rest_api.frontend_proxy.id
  stage_name  = "prod"
  
  lifecycle {
    create_before_destroy = true
  }
}

# Konfiguracja CORS dla API Gateway - obsługa OPTIONS
resource "aws_api_gateway_method" "proxy_options" {
  rest_api_id   = aws_api_gateway_rest_api.frontend_proxy.id
  resource_id   = aws_api_gateway_resource.proxy_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.frontend_proxy.id
  resource_id = aws_api_gateway_resource.proxy_resource.id
  http_method = aws_api_gateway_method.proxy_options.http_method
  
  type = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "proxy_options_response" {
  rest_api_id = aws_api_gateway_rest_api.frontend_proxy.id
  resource_id = aws_api_gateway_resource.proxy_resource.id
  http_method = aws_api_gateway_method.proxy_options.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "proxy_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.frontend_proxy.id
  resource_id = aws_api_gateway_resource.proxy_resource.id
  http_method = aws_api_gateway_method.proxy_options.http_method
  status_code = aws_api_gateway_method_response.proxy_options_response.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT,DELETE'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Usuwamy problematyczną odpowiedź integracji i używamy tylko metody OPTIONS do obsługi CORS