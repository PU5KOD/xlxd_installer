#!/bin/bash
# A tool to install XLXD, your own D-Star Reflector.
# For more information, please visit https://xlxbbs.epf.lu/
# Customized by Daniel K., PU5KOD
# Lets begin!!!

# root user check
if [ "$(whoami)" != "root" ]; then
    echo "You must be root to run this script!"
    exit 1
fi

# Distro check
if [ ! -e "/etc/debian_version" ]; then
    echo "This script is only tested on Debian-based distributions."
    exit 1
fi

DIRDIR=$(pwd)
LOCAL_IP=$(hostname -I | awk '{print $1}')
INFREF="https://n5amd.com/digital-radio-how-tos/create-xlx-xrf-d-star-reflector/"
XLXDREPO="https://github.com/PU5KOD/xlxd.git"
DMRIDURL="http://xlxapi.rlx.lu/api/exportdmr.php"
WEBDIR="/var/www/html/xlxd"
XLXINSTDIR="/usr/src"
APPS="git git-core make build-essential g++ apache2 php libapache2-mod-php php-cli php-xml php-mbstring php-curl"

# DATA INPUT
clear
echo "_________________________________________________________________________"
echo ""
echo "Installer of the XLX Multiprotocol Ham Radio Reflector and its dashboard"
echo ""
echo "Below you will be asked for some information, answer the requested"
echo "values or, if applicable, to accept the suggested value press [ENTER]"
echo "_________________________________________________________________________"
echo ""
echo ""
echo "REFLECTOR DATA INPUT"
echo "===================="
echo ""
while true; do
    echo "Mandatory"
    read -r -p "01. What are the 3 digits of the XLX reflector that will be used? (e.g., 300, US1, BRA) " XRFDIGIT
    if [ -z "$XRFDIGIT" ]; then
        echo "Error: This field is mandatory and cannot be empty. Try again!"
    else
        XRFDIGIT=$(echo "$XRFDIGIT" | tr '[:lower:]' '[:upper:]')
        if [[ "$XRFDIGIT" =~ ^[A-Z0-9]{3}$ ]]; then
            break
        else
            echo "Error: Must be exactly 3 alphanumeric characters (e.g., 032, USA, BRA). Try again!"
        fi
    fi
done
XRFNUM=XLX$XRFDIGIT
echo "Using: $XRFNUM"
while true; do
echo "_________________________________________________________________________"
echo ""
    echo "Mandatory"
    read -r -p "02. What is the web address (FQDN) of the reflector dashboard? e.g., xlx.domain.com " XLXDOMAIN
    if [ -z "$XLXDOMAIN" ]; then
        echo "Error: This field is mandatory and cannot be empty. Try again!"
    else
        break
    fi
done
echo "Using: $XLXDOMAIN"
while true; do
echo "_________________________________________________________________________"
echo ""
    echo "Mandatory"
    read -r -p "03. What is the sysop e-mail address? " EMAIL
    if [ -z "$EMAIL" ]; then
        echo "Error: This field is mandatory and cannot be empty. Try again!"
    else
        break
    fi
done
echo "Using: $EMAIL"
while true; do
echo "_________________________________________________________________________"
echo ""
    echo "Mandatory"
    read -r -p "04. What is the sysop callsign? " CALLSIGN
    if [ -z "$CALLSIGN" ]; then
        echo "Error: This field is mandatory and cannot be empty. Try again!"
    else
        break
    fi
done
echo "Using: $CALLSIGN"
while true; do
echo "_________________________________________________________________________"
echo ""
    echo "Mandatory"
    read -r -p "05. What is the country of the reflector? " COUNTRY
    if [ -z "$COUNTRY" ]; then
        echo "Error: This field is mandatory and cannot be empty. Try again!"
    else
        break
    fi
done
echo "Using: $COUNTRY"
echo "_________________________________________________________________________"
echo ""
COMMENT_DEFAULT="$XRFNUM Multiprotocol Reflector by $CALLSIGN, info: $EMAIL"
echo "Suggested for next field: \"$COMMENT_DEFAULT\""
while true; do
    read -r -p "06. What is the comment to be shown in the XLX Reflectors list? " COMMENT
    COMMENT=${COMMENT:-"$COMMENT_DEFAULT"}
    if [ ${#COMMENT} -le 100 ]; then
        break
    else
        echo "Error: Comment must be max 100 characters. Please try again!"
    fi
done
echo "Using: $COMMENT"
echo "_________________________________________________________________________"
echo ""
echo "Suggested for next field: \"$XRFNUM\""
read -r -p "07. Custom text on header of the dashboard webpage. " HEADER
HEADER=${HEADER:-$XRFNUM}
echo "Using: $HEADER"
while true; do
echo "_________________________________________________________________________"
echo ""
    echo "Suggested for next field: 6"
    read -r -p "08. How many active modules does the reflector have? (1-26) " MODQTD
    MODQTD=${MODQTD:-6}
    if [[ "$MODQTD" =~ ^[0-9]+$ && "$MODQTD" -ge 1 && "$MODQTD" -le 26 ]]; then
        break
    else
        echo "Error: Must be a number between 1 and 26. Try again!"
    fi
done
echo "Using: $MODQTD"
# YSFNAME e YSFDESC input
while true; do
echo "_________________________________________________________________________"
echo ""
    echo "Suggested for next field: \"$XRFNUM\""
    echo "09. At https://register.ysfreflector.de the list of YSF reflectors is shown."
    echo -n "    What name will this reflector have to appear in this list? (max. 16 characters) "
    read -r YSFNAME
    YSFNAME=${YSFNAME:-$XRFNUM}
    if [ ${#YSFNAME} -le 16 ]; then
        break
    else
        echo "Error: Name must be max 16 characters. Please try again!"
    fi
done
echo "Using: $YSFNAME"
while true; do
echo "_________________________________________________________________________"
echo ""
    echo "Suggested for next field: \"$XLXDOMAIN\""
    echo -n "10. And what will be his description to appear on this list? (max. 16 characters) "
    read -r YSFDESC
    YSFDESC=${YSFDESC:-$XLXDOMAIN}
    if [ ${#YSFDESC} -le 16 ]; then
        break
    else
        echo "Error: Description must be max 16 characters. Please try again!"
    fi
done
echo "Using: $YSFDESC"
# Fill with spaces on the right until reach 16 characters
YSFNAME=$(printf "%-16s" "$YSFNAME")
YSFDESC=$(printf "%-16s" "$YSFDESC")
# Function to convert string into array C
to_c_array() {
    local input="$1"
    local output=""
    for ((i=0; i<16; i++)); do
        char="${input:$i:1}"
        if [ -z "$char" ] || [ "$char" = " " ]; then
            output="$output' '"
        else
            output="$output'$char'"
        fi
        if [ $i -lt 15 ]; then
            output="$output,"
        fi
    done
    echo "$output"
}
# Generate arrays C
YSFNAME_ARRAY=$(to_c_array "$YSFNAME")
YSFDESC_ARRAY=$(to_c_array "$YSFDESC")
while true; do
echo "_________________________________________________________________________"
echo ""
    echo "Suggested for next field: 42000"
    read -r -p "11. What is the YSF UDP port number? (1-65535) " YSFPORT
    YSFPORT=${YSFPORT:-42000}
    if [[ "$YSFPORT" =~ ^[0-9]+$ && "$YSFPORT" -ge 1 && "$YSFPORT" -le 65535 ]]; then
        break
    else
        echo "Error: Must be a number between 1 and 65535. Try again!"
    fi
done
echo "Using: $YSFPORT"
while true; do
echo "_________________________________________________________________________"
echo ""
    echo "Suggested for next field: 433125000"
    read -r -p "12. What is the frequency of YSF Wires-X? (In Hertz, 9 digits, e.g., 433125000) " YSFFREQ
    YSFFREQ=${YSFFREQ:-433125000}
    if [[ "$YSFFREQ" =~ ^[0-9]{9}$ ]]; then
        break
    else
        echo "Error: Must be exactly 9 numeric digits (e.g., 433125000). Try again!"
    fi
done
echo "Using: $YSFFREQ"
echo "_________________________________________________________________________"
echo ""
echo "Suggested for next field: 1"
read -r -p "13. Is YSF auto-link enable? (1 = Yes / 0 = No) " AUTOLINK
AUTOLINK=${AUTOLINK:-1}
echo "Using: $AUTOLINK"
VALID_MODULES=($(echo {A..Z} | cut -d' ' -f1-"$MODQTD"))
if [ "$AUTOLINK" -eq 1 ]; then
    while true; do
    echo "_________________________________________________________________________"
    echo ""
        echo "Suggested for next field: C"
        read -r -p "14. What module to be auto-link? (one of ${VALID_MODULES[*]}) " MODAUTO
        MODAUTO=${MODAUTO:-C}
        MODAUTO=$(echo "$MODAUTO" | tr '[:lower:]' '[:upper:]')
        if [[ " ${VALID_MODULES[@]} " =~ " $MODAUTO " ]]; then
            break
        else
            echo "Invalid input for YSF autolink module. Must be one of ${VALID_MODULES[*]}. Try again!"
        fi
    done
    echo "Using: $MODAUTO"
fi

echo ""
echo "UPDATING OS..."
echo "=============="
echo ""

apt update && apt full-upgrade -y

echo ""
echo "INSTALLING DEPENDENCIES..."
echo "=========================="
echo ""

mkdir -p "$XLXINSTDIR"
apt -y install $APPS

if [ -e "$XLXINSTDIR/xlxd/src/xlxd" ]; then
    echo "=================================================================================="
    echo "|           XLXD ALREADY COMPILED!!! Delete the following directories            |"
    echo "|    '/usr/src/xlxd', '/xlxd', '/var/www/html/xlxd' and the following files      |"
    echo "| '/etc/init.d/xlxd.*', 'var/log/xlxd.*' and '/etc/apache2/sites-available/xlx*' |"
    echo "=================================================================================="
    exit 1
else
    echo ""
    echo "DOWNLOADING APPLICATION..."
    echo "=========================="
    echo ""
    cd "$XLXINSTDIR"
    git clone "$XLXDREPO"
    cd "$XLXINSTDIR/xlxd/src"
    make clean
    MAINCONFIG="$XLXINSTDIR/xlxd/src/main.h"
    sed -i "s|\(NB_OF_MODULES\s*\)\([0-9]*\)|\1$MODQTD|g" "$MAINCONFIG"
    sed -i "s|\(YSF_PORT\s*\)\([0-9]*\)|\1$YSFPORT|g" "$MAINCONFIG"
    sed -i "s|\(YSF_DEFAULT_NODE_TX_FREQ\s*\)\([0-9]*\)|\1$YSFFREQ|g" "$MAINCONFIG"
    sed -i "s|\(YSF_DEFAULT_NODE_RX_FREQ\s*\)\([0-9]*\)|\1$YSFFREQ|g" "$MAINCONFIG"
    sed -i "s|\(YSF_AUTOLINK_ENABLE\s*\)\([0-9]*\)|\1$AUTOLINK|g" "$MAINCONFIG"
    if [ "$AUTOLINK" -eq 1 ]; then
        sed -i "s|\(YSF_AUTOLINK_MODULE\s*\)'\([A-Z]*\)'|\1'$MODAUTO'|g" "$MAINCONFIG"
    fi
    CYSF_FILE="$XLXINSTDIR/xlxd/src/cysfprotocol.cpp"
    sed -i "s|uint8 callsign\[16\];|uint8 callsign[16] = { $YSFNAME_ARRAY };|g" "$CYSF_FILE"
    sed -i "s|uint8 description\[\] = { 'X','L','X',' ','r','e','f','l','e','c','t','o','r',' ' };|uint8 description[] = { $YSFDESC_ARRAY };|g" "$CYSF_FILE"
    echo ""
    echo "COMPILING..."
    echo "============"
    echo ""
    make
    make install
fi

if [ -e "$XLXINSTDIR/xlxd/src/xlxd" ]; then
    echo ""
    echo "==============================="
    echo "|  COMPILATION SUCCESSFUL!!!  |"
    echo "==============================="
    echo ""
else
    echo ""
    echo "======================================================"
    echo "|  Compilation FAILED. Check the output for errors.  |"
    echo "======================================================"
    echo ""
    exit 1
fi
echo "COPYING FILES..."
echo "================"
echo ""
mkdir -p /xlxd
mkdir -p "$WEBDIR"
touch /var/log/xlxd.xml
wget -O /xlxd/dmrid.dat "$DMRIDURL"
echo "INSTALLING DASHBOARD..."
echo "======================="
echo ""
cp -R "$XLXINSTDIR/xlxd/dashboard/"* "$WEBDIR/"
cp "$XLXINSTDIR/xlxd/scripts/xlxd" /etc/init.d/xlxd
sed -i "s|XLXXXX 172.23.127.100 127.0.0.1|$XRFNUM $LOCAL_IP 127.0.0.1|g" /etc/init.d/xlxd
/usr/sbin/update-rc.d xlxd defaults

XLXCONFIG="$WEBDIR/pgs/config.inc.php"
sed -i "s|your_email|$EMAIL|g" "$XLXCONFIG"
sed -i "s|LX1IQ|$CALLSIGN|g" "$XLXCONFIG"
sed -i "s|custom_header|$HEADER|g" "$XLXCONFIG"
sed -i "s#http://your_dashboard#http://$XLXDOMAIN#g" "$XLXCONFIG"
sed -i "s|your_country|$COUNTRY|g" "$XLXCONFIG"
sed -i "s|your_comment|$COMMENT|g" "$XLXCONFIG"
sed -i "s#/tmp/callinghome.php#/xlxd/callinghome.php#g" "$XLXCONFIG"
sed -i "s#/tmp/lastcallhome.php#/xlxd/lastcallhome.php#g" "$XLXCONFIG"

cp "$DIRDIR/templates/apache.tbd.conf" /etc/apache2/sites-available/"$XLXDOMAIN".conf
sed -i "s|apache.tbd|$XLXDOMAIN|g" /etc/apache2/sites-available/"$XLXDOMAIN".conf
sed -i "s#ysf-xlxd#html/xlxd#g" /etc/apache2/sites-available/"$XLXDOMAIN".conf

chown -R www-data:www-data /var/log/xlxd.xml
chown -R www-data:www-data "$WEBDIR/"
chown -R www-data:www-data /xlxd/

/usr/sbin/a2ensite "$XLXDOMAIN".conf
/usr/sbin/a2dissite 000-default
systemctl stop apache2
systemctl start apache2
systemctl daemon-reload
echo ""
echo "========================================="
echo "|  REFLECTOR INSTALLED SUCCESSFULLY!!!  |"
echo "========================================="
echo ""
echo "STARTING $XRFNUM REFLECTOR..."
echo "============================"
echo ""
systemctl enable xlxd
systemctl start xlxd | echo "Finishing, please wait......."

echo ""
echo "==========================================================================="
echo "  Your Reflector $XRFNUM is now installed and running."
echo "  For Public Reflectors:"
echo "  If your XLX number is available it's expected to be listed"
echo "  on the public list shortly, typically within an hour."
echo "  If you don't want the reflector to be published just set callinghome"
echo "  to [false] in the main file in $XLXCONFIG."
echo "  Many other settings can be changed in this file."
echo "  More Information: $INFREF"
echo "  Your $XRFNUM dashboard should now be accessible at http://$XLXDOMAIN "
echo "  To get your site certified with https visit certbot.eff.org"
echo "==========================================================================="
