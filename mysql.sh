########################################################################################################################
# Find Us                                                                                                              #
# Author: Mehmet ÖĞMEN                                                                                                 #
# Web   : https://x-shell.codes/scripts/mysql                                                                          #
# Email : mailto:mysql.script@x-shell.codes                                                                            #
# GitHub: https://github.com/x-shell-codes/mysql                                                                       #
########################################################################################################################
# Contact The Developer:                                                                                               #
# https://www.mehmetogmen.com.tr - mailto:www@mehmetogmen.com.tr                                                       #
########################################################################################################################

########################################################################################################################
# Constants                                                                                                            #
########################################################################################################################
NORMAL_LINE=$(tput sgr0)
RED_LINE=$(tput setaf 1)
YELLOW_LINE=$(tput setaf 3)
GREEN_LINE=$(tput setaf 2)
BLUE_LINE=$(tput setaf 4)
POWDER_BLUE_LINE=$(tput setaf 153)
BRIGHT_LINE=$(tput bold)
REVERSE_LINE=$(tput smso)
UNDER_LINE=$(tput smul)

########################################################################################################################
# Line Helper Functions                                                                                                #
########################################################################################################################
function ErrorLine() {
    echo "${RED_LINE}$1${NORMAL_LINE}"
  echo "${RED_LINE}$1${NORMAL_LINE}"
}

function WarningLine() {
    echo "${YELLOW_LINE}$1${NORMAL_LINE}"
  echo "${YELLOW_LINE}$1${NORMAL_LINE}"
}

function SuccessLine() {
    echo "${GREEN_LINE}$1${NORMAL_LINE}"
  echo "${GREEN_LINE}$1${NORMAL_LINE}"
}

function InfoLine() {
    echo "${BLUE_LINE}$1${NORMAL_LINE}"
  echo "${BLUE_LINE}$1${NORMAL_LINE}"
}

########################################################################################################################
# Version                                                                                                              #
########################################################################################################################
function Version() {
  echo "MySQL install script version 1.0.0"
  echo
  echo "${BRIGHT_LINE}${UNDER_LINE}Find Us${NORMAL}"
  echo "${BRIGHT_LINE}Author${NORMAL}: Mehmet ÖĞMEN"
  echo "${BRIGHT_LINE}Web${NORMAL}   : https://x-shell.codes/scripts/mysql"
  echo "${BRIGHT_LINE}Email${NORMAL} : mailto:mysql.script@x-shell.codes"
  echo "${BRIGHT_LINE}GitHub${NORMAL}: https://github.com/x-shell-codes/mysql"
}

########################################################################################################################
# Help                                                                                                                 #
########################################################################################################################
function Help() {
  echo "It install the basic packages required for x-shell.codes projects."
  echo "MySQL install & configuration script."
  echo
  echo "Options:"
  echo "-p | --password    MySQL dba user password."
  echo "-r | --isRemote    Is remote access server? (true/false)."
  echo "-h | --help        Display this help."
  echo "-V | --version     Print software version and exit."
  echo
  echo "For more details see https://github.com/x-shell-codes/mysql."
}

########################################################################################################################
# Arguments Parsing                                                                                                    #
########################################################################################################################
password="secret"
isRemote="true"

for i in "$@"; do
  case $i in
  -p=* | --password=*)
    password="${i#*=}"

    if [ -z "$password" ]; then
      ErrorLine "Password cannot be empty."
      exit
    fi

    shift
    ;;
  -r=* | --isRemote=*)
    isRemote="${i#*=}"

    if [ "$isRemote" != "true" ] && [ "$isRemote" != "false" ]; then
      ErrorLine "Is remote value is invalid."
      Help
      exit
    fi

    shift
    ;;
  -h | --help)
    Help
    exit
    ;;
  -V | --version)
    Version
    exit
    ;;
  -* | --*)
    ErrorLine "Unexpected option: $1"
    echo
    echo "Help:"
    Help
    exit
    ;;
  esac
done

########################################################################################################################
# Main Program                                                                                                         #
########################################################################################################################
echo "${POWDER_BLUE_LINE}${BRIGHT_LINE}${REVERSE_LINE}MYSQl INSTALLATION${NORMAL_LINE}"

CheckRootUser

export DEBIAN_FRONTEND=noninteractive

apt install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y --force-yes pkg-config \
 build-essential fail2ban gcc g++ libmcrypt4 libpcre3-dev make python3 python3-pip sendmail supervisor ufw curl whois\
  zip unzip zsh ncdu uuid-runtime acl libpng-dev libmagickwand-dev libpcre2-dev cron jq net-tools

# Add MySQL Keys...
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 467B942D3A79BD29

# Configure MySQL Repositories If Required
# Convert a version string into an integer.
function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

UBUNTU_VERSION=$(lsb_release -rs)
echo "Server on Ubuntu ${UBUNTU_VERSION}"
if [ $(version $UBUNTU_VERSION) -le $(version "20.04") ]; then
  wget -c https://dev.mysql.com/get/mysql-apt-config_0.8.15-1_all.deb
  dpkg --install mysql-apt-config_0.8.15-1_all.deb

  apt update
fi

# Set The Automated Root Password
debconf-set-selections <<<"mysql-community-server mysql-community-server/data-dir select ''"
debconf-set-selections <<<"mysql-community-server mysql-community-server/root-pass password $password"
debconf-set-selections <<<"mysql-community-server mysql-community-server/re-root-pass password $password"

# Install MySQL
apt install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y --force-yes mysql-community-server
apt install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y --force-yes mysql-server

# Configure Password Expiration
echo "default_password_lifetime = 0" >>/etc/mysql/mysql.conf.d/mysqld.cnf

# Set Character Set
echo "" >>/etc/mysql/my.cnf
echo "[mysqld]" >>/etc/mysql/my.cnf
echo "default_authentication_plugin=mysql_native_password" >>/etc/mysql/my.cnf
echo "skip-log-bin" >>/etc/mysql/my.cnf

# Configure Max Connections
RAM=$(awk '/^MemTotal:/{printf "%3.0f", $2 / (1024 * 1024)}' /proc/meminfo)
MAX_CONNECTIONS=$((70 * $RAM))
REAL_MAX_CONNECTIONS=$((MAX_CONNECTIONS > 70 ? MAX_CONNECTIONS : 100))
sed -i "s/^max_connections.*=.*/max_connections=${REAL_MAX_CONNECTIONS}/" /etc/mysql/my.cnf

mysql --user="root" -e "CREATE USER 'dba'@'localhost' IDENTIFIED BY '$password';"
mysql --user="root" -e "GRANT ALL PRIVILEGES ON *.* TO 'dba'@'localhost' WITH GRANT OPTION;"

if [ "$isRemote" == "true" ]; then
  if grep -q "bind-address" /etc/mysql/mysql.conf.d/mysqld.cnf; then
    sed -i '/^bind-address/s/bind-address.*=.*/bind-address = */' /etc/mysql/mysql.conf.d/mysqld.cnf
  else
    echo "bind-address = *" >>/etc/mysql/mysql.conf.d/mysqld.cnf
  fi

  mysql --user="root" -e "CREATE USER 'dba'@'%' IDENTIFIED BY '$password';"
  mysql --user="root" -e "GRANT ALL PRIVILEGES ON *.* TO 'dba'@'%' WITH GRANT OPTION;"
fi

# Create The Initial Database If Specified
mysql --user="root" -e "CREATE DATABASE system CHARACTER SET utf8 COLLATE utf8_unicode_ci;"

mysql --user="root" -e "FLUSH PRIVILEGES;"
service mysql restart

# Configure MySQL To Start On Boot
systemctl enable mysql.service
