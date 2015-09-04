print_info () {

	local s=$1
 
	echo "#################################################"
	echo "$1"
	echo "#################################################"
}

print_info "Updating the hosts file"

echo "127.0.0.1 $1" >> "/etc/hosts"

print_info "Updating the Apache Configuration"

vhost="<VirtualHost *:80>
  ServerName $1
	DocumentRoot /media/sf_Code/$2
	<Directory \"/media/sf_Code/$2\">
		Order allow,deny
		Allow from all
		Require all granted
		AllowOverride All
	</Directory>
</VirtualHost>"

echo "$vhost" >> "/etc/apache2/sites-available/$1.conf"

ln -s "/etc/apache2/sites-available/$1.conf" "/etc/apache2/sites-enabled/$1.conf"

print_info "Restarting Apache"

/etc/init.d/apache2 reload
