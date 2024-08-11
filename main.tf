provider "aws" {
  region = "us-east-1"  
}

# Define the EC2 instance
data "aws_ami" "myimage" {
  most_recent = true
  owners = [ "amazon" ]

   filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*"]
  }
}

resource "aws_instance" "laravel" {
  ami = data.aws_ami.myimage.image_id
  instance_type = "t2.micro"

  # User data script to install and configure Nginx, PHP, and Laravel
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install -y nginx1
              amazon-linux-extras install -y php8.0
              yum install -y php-fpm php-mbstring php-xml php-json php-zip unzip git

              # Configure Nginx
              cat <<EOF2 > /etc/nginx/conf.d/laravel.conf
              server {
                  listen 80;
                  server_name localhost;

                  root /var/www/html/cargo-app/public;
                  index index.php index.html index.htm;

                  location / {
                      try_files \$uri \$uri/ /index.php?\$query_string;
                  }

                  location ~ \.php$ {
                      include fastcgi_params;
                      fastcgi_pass unix:/run/php-fpm/www.sock;
                      fastcgi_index index.php;
                      fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                  }

                  location ~ /\.ht {
                      deny all;
                  }

                  error_log /var/log/nginx/laravel_error.log;
                  access_log /var/log/nginx/laravel_access.log;
              }
              EOF2

              systemctl start nginx
              systemctl enable nginx

              # Install and configure PHP-FPM
              cat <<EOF3 > /etc/php-fpm.d/www.conf
              [www]
              user = nginx
              group = nginx
              listen = /run/php-fpm/www.sock
              listen.owner = nginx
              listen.group = nginx
              pm = dynamic
              pm.max_children = 5
              pm.start_servers = 2
              pm.min_spare_servers = 1
              pm.max_spare_servers = 3
              EOF3

              systemctl start php-fpm
              systemctl enable php-fpm

              # Download and install Laravel, this is an example if your code is in a git repo
              cd /var/www/html
              git clone https://github.com/your-repo/cargo-app.git
              cd cargo-app
              composer install
              cp .env.example .env
              php artisan key:generate
              php artisan migrate

              # Set permissions
              chown -R nginx:nginx /var/www/html/cargo-app
              chmod -R 775 /var/www/html/cargo-app/storage
              chmod -R 775 /var/www/html/cargo-app/bootstrap/cache
              EOF
} #You can edit user data to whatever meet your needss

# Define the security group
resource "aws_security_group" "rule_laravel" {
  name        = "rule_laravel"
  description = "Allow HTTP,HTTPS,SSH traffic"


  tags = {
    Name = "laravel_rules"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_htps" {
  security_group_id = aws_security_group.rule_laravel.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.rule_laravel.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "allowssh" {
  security_group_id = aws_security_group.rule_laravel.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
} #ssh shouldn't be allowed from everwhere but this is test instance

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.rule_laravel.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}



# Output the public IP of the EC2 instance
output "instance_ip" {
  value = aws_instance.laravel.public_ip
}
