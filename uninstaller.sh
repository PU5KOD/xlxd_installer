#!/bin/bash
echo "XLX Uninstaller"
echo ""
read -r -p "What is the web address (FQDN) of the reflector dashboard? " XLXDOMAIN
sudo systemctl stop xlxd.service
sudo systemctl disable xlxd.service
sudo systemctl stop xlxecho.service
sudo systemctl disable xlxecho.service
sudo rm /etc/systemd/system/xlxecho.service
/usr/sbin/a2dissite $XLXDOMAIN.conf
/usr/sbin/a2ensite 000-default
sudo systemctl reload apache2.service
sudo rm -r /usr/src/xlxd/ /xlxd/ /var/www/html/xlxd/ /usr/src/XLXEcho/
sudo rm /etc/init.d/xlxd /var/log/xlxd.* /etc/apache2/sites-available/$XLXDOMAIN.conf
sudo systemctl daemon-reload
echo ""
echo "Uninstallation completed successfully!"
