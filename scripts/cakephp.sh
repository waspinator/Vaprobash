#!/usr/bin/env bash
#!/usr/bin/env bash

echo ">>> Installing CakePHP"

# Test if PHP is installed
php -v > /dev/null 2>&1
PHP_IS_INSTALLED=$?

# Test if HHVM is installed
hhvm --version > /dev/null 2>&1
HHVM_IS_INSTALLED=$?

[[ $PHP_IS_INSTALLED -ne 0 ]] && { printf "!!! PHP is not installed.\n    Installing CakePHP aborted!\n"; exit 0; }

# Test if Composer is installed
composer -v > /dev/null 2>&1 || { printf "!!! Composer is not installed.\n    Installing CakePHP aborted!"; exit 0; }

# Test if Server IP is set in Vagrantfile
[[ -z "$1" ]] && { printf "!!! IP address not set. Check the Vagrantfile.\n    Installing CakePHP aborted!\n"; exit 0; }

# Check if CakePHP root is set. If not set use default
if [[ -z $2 ]]; then
    cakephp_root_folder="/vagrant/cakephp"
else
    cakephp_root_folder="$2"
fi

cakephp_public_folder="$cakephp_root_folder/public"

# Test if Apache or Nginx is installed
nginx -v > /dev/null 2>&1
NGINX_IS_INSTALLED=$?

apache2 -v > /dev/null 2>&1
APACHE_IS_INSTALLED=$?

# Create CakePHP folder if needed
if [[ ! -d $cakephp_root_folder ]]; then
    mkdir -p $cakephp_root_folder
fi

if [[ ! -f "$cakephp_root_folder/composer.json" ]]; then
    composer create-project --prefer-dist cakephp/app $cakephp_root_folder

else
    # Go to vagrant folder
    cd $cakephp_root_folder
    composer install --prefer-dist

    # Go to the previous folder
    cd -
fi

if [[ $NGINX_IS_INSTALLED -eq 0 ]]; then
    # Change default vhost created
    sudo sed -i "s@root /vagrant@root $cakephp_public_folder@" /etc/nginx/sites-available/vagrant
    sudo service nginx reload
fi

if [[ $APACHE_IS_INSTALLED -eq 0 ]]; then
    # Find and replace to find public_folder and replace with cakephp_public_folder
    # Change DocumentRoot
    # Change ProxyPassMatch fcgi path
    # Change <Directory ...> path
    sudo sed -i "s@$3@$cakephp_public_folder@" /etc/apache2/sites-available/$1.xip.io.conf
    sudo service apache2 reload
fi
