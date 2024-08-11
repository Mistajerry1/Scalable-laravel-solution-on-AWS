An easy solution to host laravel on AWS.
*** Steps i took and setbacks i faced***

* create ec2 
# You can easily write a user data script install webserver during creation (nginx or httpd)

*2 connect to ec2 using ssh or anyway
# ssh -i /path/to/your-key-pair.pem ec2-user or ubuntu@your-ec2-public-dns

* install webserver and dependencies 
 sudo yum update -y
 sudo yum install -y httpd
# For PHP and dependencies
 sudo yum install -y php
 sudo yum install -y php-mbstring php-xml php-json php-zip
# For Node.js
 curl -sL https://rpm.nodesource.com/setup_22.x | sudo bash -
 sudo yum install -y nodejs

* start and enable the webserver 
 sudo systemctl start httpd
 sudo systemctl enable httpd

* install composer
 php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
 php composer-setup.php --install-dir=/usr/local/bin --filename=composer
 php -r "unlink('composer-setup.php');"

* deploy your application
# i had issues with ssh so i used sftp 
- sftp -i /path/to/your-key-pair.pem ec2-user@your-ec2-public-dns
- put /path/to/local/file.txt

*


