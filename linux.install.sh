#!/usr/bin/env bash

###############################
# Installer by Varg. ver 0.08 #
###############################

C_BLUE='\033[36m'
C_RED='\033[31m'
C_GREEN='\033[32m'
C_DEF='\033[0m'
C_BOLD='\033[1m'

############################ 0.00 Log file #####################################
exec 2>lin.inst.errors.log

############################ FUNCTIONS #########################################
############## Log Func #################
logfile () {

echo ""
echo -en "$C_GREEN Do you want to see error log? (yes or no) $C_DEF"
echo ""

read LOGFILE

case $LOGFILE in
yes | y)
	less lin.inst.errors.log
	;;
no | n)
	exit 0
esac

}

############### SELINUX Permissive function ##################
change_SE () {
        setenforce Permissive
        sed -i "/SELINUX=enforcing/c SELINUX=permissive" /etc/selinux/config
}

############### Vsftpd installation function #################
config_vsftpd() {
if [ "$OS" = "CentOS7" ]; then
OSVSFTPD=$CENTOSVSFTPD
else
OSVSFTPD=$DEBVSFTPD
fi
cp $OSVSFTPD/vsftpd.conf $OSVSFTPD/vsftpd.conf.orig
cat > $OSVSFTPD/vsftpd.conf <<EOF
anonymous_enable=NO

local_enable=YES

write_enable=YES

local_umask=022

dirmessage_enable=YES

connect_from_port_20=YES

listen=YES
listen_ipv6=NO

pam_service_name=vsftpd

userlist_enable=YES
userlist_file=$OSVSFTPD/vsftpd.userlist
userlist_deny=NO

chroot_local_user=YES

allow_writeable_chroot=YES

log_ftp_protocol=YES
xferlog_enable=YES
xferlog_std_format=NO
vsftpd_log_file=/var/log/vsftpd.log
EOF

touch $OSVSFTPD/vsftpd.userlist

echo ""
echo -en "$C_GREEN Do you want to add new ftp user? (yes or no) $C_DEF \n"
echo ""

read NEWFTPUSER

case $NEWFTPUSER in
yes | y)
	echo ""
	echo -en "$C_GREEN Please enter username $C_DEF \n" 
	echo ""
	read FTPUSER
	echo ""
        echo -en "$C_GREEN Please enter home directory for user $FTPUSER (example:/home/$FTPUSER) $C_DEF \n" 
        echo ""
        read FTPHOME
	
	useradd -s /bin/false -d $FTPHOME -m $FTPUSER
	echo "$FTPUSER" > $OSVSFTPD/vsftpd.userlist
	echo "/bin/false" >> /etc/shells
	passwd $FTPUSER
;;
*)
esac

systemctl restart vsftpd
systemctl enable vsftpd

echo ""
echo -en "$C_BLUE vsftpd was successfully installed $C_DEF \n"
echo ""
if [[ "$NEWFTPUSER" = "yes" || "$NEWFTPUSER" = "y" ]]; then 
	echo -en "$C_BLUE User $FTPUSER was successfully added $C_DEF \n"
	echo ""
else
	echo ""
fi
echo -en "$C_RED Please don't forget add firewall rules for ftp! Have a nice day! $C_DEF \n" 
echo ""
netstat -tulpn | grep ftp
echo ""

}

################################# Zabbix-server setup function #####################
config_zabbix_server () {

	echo -en "$C_GREEN Please, enter database name for zabbix server: $C_DEF \n"
	read z_s_db_name
	echo -en "$C_GREEN Please, enter username for base ${z_s_db_name}: $C_DEF \n"
	read z_s_username
	echo -en "$C_GREEN Please, enter password for user ${z_s_username}: $C_DEF \n"
	read z_s_passwd
	mysql -e "create database ${z_s_db_name} character set utf8 collate utf8_bin;"
	mysql -e "grant all privileges on ${z_s_db_name}.* to ${z_s_username}@localhost identified by '${z_s_passwd}';"
	zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u${z_s_username} -p${z_s_passwd} ${z_s_db_name}

	echo -en "$C_BLUE \n"
	echo "Zabbix-server:"
	echo "DB name: ${z_s_db_name}"
	echo "DB username: ${z_s_username}"
	echo "DB name: ${z_s_passwd}"
	echo -en "$C_DEF \n"

	zabbix_conf=/etc/zabbix/zabbix_server.conf
	if [ "$OS" = "CentOS7" ]; then
		httpd_conf=/etc/httpd/conf.d/zabbix.conf
	else
		httpd_conf=/etc/apache2/conf-available/zabbix.conf
	fi

	sed -i "/DBName=zabbix/c DBName=${z_s_db_name}" $zabbix_conf
	sed -i "/DBUser=zabbix/c DBUser=${z_s_username}" $zabbix_conf
	sed -i "/AlertScriptsPath=\/usr\/lib\/zabbix\/alertscripts/c AlertScriptsPath=\/etc\/zabbix\/alertscripts" $zabbix_conf
	sed -i "/ExternalScripts=\/usr\/lib\/zabbix\/externalscripts/c ExternalScripts=\/etc\/zabbix\/externalscripts" $zabbix_conf
	sed -i "/# DBPassword=/c DBPassword=${z_s_passwd}" $zabbix_conf

	timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
	sed -i "/# php_value date.timezone Europe\/Riga/c php_value date.timezone $timezone " $httpd_conf >> $httpd_conf
	
	systemctl start zabbix-server
	systemctl enable zabbix-server

	if [ "$OS" = "CentOS7" ]; then
		setenforce Permissive
        	systemctl stop firewalld
	        systemctl disable firewalld
		systemctl start httpd
	        systemctl enable httpd
	else
		systemctl restart apache2
                systemctl enable apache2
	fi

	host_ip=$(hostname -I | sed s/' '//)
	echo ""
	echo -en "$C_RED Warning!!! firewalld disabled!!! SELINUX in Permissive mode!!! $C_DEF \n"
	echo -en "$C_BLUE Continue to setup zabbix-server 3.4 accessing the web http://${host_ip}/zabbix $C_DEF \n"
	echo ""	
}

############################### Create .my.cnf function ################################
create_my.cnf () {
	echo ""
	echo -en "$C_BLUE Create .my.cnf $C_DEF \n"
	echo -en "$C_GREEN Please, repeat password for MariaDB: $C_DEF \n"
	echo ""
	read MDB_PASS
	echo "[client]" > /root/.my.cnf
	echo "password = $MDB_PASS" >> /root/.my.cnf
}

################################### 0.01 Check root ##############################
if [ "$(id -u)" != "0" ];  then
  echo ""
  echo -en "$C_BLUE ===== Hello $(whoami)! You need to be root to run this script! ===== $C_DEF \n"
  echo ""
  exit 1
else
  echo ""
  echo -en "$C_BLUE ====================== Hello $(whoami)! ====================== $C_DEF \n"
  echo -en "$C_BLUE *** This script works only on CentOS 7; Debian 8, Debian 9 *** $C_DEF \n"
  echo ""
fi

################################### 0.02 Check OS TYPE & VERSION #################
if [ -f /etc/redhat-release ]; then
	OS_RELEASE=$(cat /etc/redhat-release | awk '{print $1}')
	OS_VERSION=$(cat /etc/os-release | grep VERSION_ID | awk -F '\"' '{print $2}')
	if [ $OS_RELEASE == CentOS ] && [ $OS_VERSION == 7 ]; then
		OS="CentOS7"; echo -en "$C_BLUE ========== $OS ========== $C_DEF \n"
	else
		echo -en "$C_RED OS not supported! $C_DEF \n"
		exit 1
	fi
elif [ -f /etc/debian_version ]; then
	OS_RELEASE=$(lsb_release -c | awk '{print $2}')
	if [ $OS_RELEASE == jessie ]; then
		OS="Debian8"; echo -en "$C_BLUE ======= $OS $OS_RELEASE ======= $C_DEF \n"
	elif [ $OS_RELEASE == stretch ]; then
                OS="Debian9"; echo -en "$C_BLUE ======= $OS $OS_RELEASE ======= $C_DEF \n"
	else
		echo -en "$C_RED OS not supported! $C_DEF \n"
                exit 1
	fi
else
	echo -en "$C_RED OS Unknown $C_DEF \n"
	exit 1
fi

################################### 0.03 Main Menu##################################
echo "----------------------------------------"
echo "|    What do you want to install?      |"
echo "----------------------------------------"
echo "|1. exit                               |"
echo "|2. mc,vim,sudo,wget,git               |"
echo "|3. vsftpd                             |"
echo "|4. fail2ban-ssh                       |"
echo "|5. zabbix-server 3.4                  |"
echo "|6. OpenVPN                            |"
echo "|7. Proxmox (Only for Debian!)         |"
echo "----------------------------------------"

read MENU

case $MENU in
	1)
 		echo ""
		echo -en "$C_BLUE Bye! $C_DEF \n"
		echo ""
		logfile
	;;
################################### 0.04 Utils installation #########################
	2)
		if [ "$OS" = "CentOS7" ]; then
			yum install mc vim sudo wget git -y
			logfile
		else
			apt-get update
			apt-get install -y mc vim sudo wget git
			logfile
		fi
	;;
################################### 0.05 vsftpd installation ########################
	3)

DEBVSFTPD=/etc
CENTOSVSFTPD=/etc/vsftpd

		if [ "$OS" = "CentOS7" ]; then
                        yum install -y vsftpd
			config_vsftpd
			logfile
                else
                        apt-get update
                        apt-get install -y vsftpd
			config_vsftpd
			logfile
                fi
        ;;
################################### 0.06 fail2ban-ssh ###############################
4)

if [ "$OS" = "CentOS7" ]; then
yum install -y epel-release
yum install -y fail2ban
	cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
# Ban hosts for 24 hours
bantime = 86400 

# List white addresses
ignoreip = 127.0.0.1/8 

# Time interval when fail2ban find activity (in seconds)
findtime = 3600

# Max try to login
maxretry = 5

[ssh-iptables]
enabled = true
filter = sshd
action = iptables[name=ssh, port=ssh, protocol=tcp]
logpath = /var/log/secure
findtime = 3600
maxretry = 5
bantime = 86400
EOF
	systemctl restart fail2ban
	systemctl enable fail2ban
	echo ""
	fail2ban-client status
	echo -en "$C_BLUE fail2ban was successfully installed! $C_DEF \n"
	logfile
else
apt-get update
apt-get install -y fail2ban
        cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
# Ban hosts for 24 hours
bantime = 86400 

# List white addresses
ignoreip = 127.0.0.1/8 

# Time interval when fail2ban find activity (in seconds)
findtime = 3600

# Max try to login
maxretry = 5

[ssh-iptables]
enabled = true
filter = sshd
action = iptables[name=ssh, port=ssh, protocol=tcp]
logpath = /var/log/auth.log
findtime = 3600
maxretry = 5
bantime = 86400
EOF
        systemctl restart fail2ban
        systemctl enable fail2ban
        echo ""
        fail2ban-client status
        echo -en "$C_BLUE fail2ban was successfully installed! $C_DEF \n"
	logfile
fi
;;
################################### 0.07 zabbix-server 3.4 ##################################
	5)
		if [ "$OS" = "CentOS7" ]; then
			rpm -ivh http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-1.el7.centos.noarch.rpm
                        yum install -y zabbix-server-mysql zabbix-web-mysql mariadb-server	
			systemctl start mariadb
		        systemctl enable mariadb

			config_zabbix_server
			logfile

		elif [ "$OS_RELEASE" = "jessie" ]; then
			wget http://repo.zabbix.com/zabbix/3.4/debian/pool/main/z/zabbix-release/zabbix-release_3.4-1+jessie_all.deb
			dpkg -i zabbix-release_3.4-1+jessie_all.deb
			apt-get update && apt-get install -y zabbix-server-mysql zabbix-frontend-php mariadb-server
			systemctl enable mysql

			create_my.cnf
                        config_zabbix_server
			logfile

		elif [ "$OS_RELEASE" = "stretch" ]; then
                	wget http://repo.zabbix.com/zabbix/3.4/debian/pool/main/z/zabbix-release/zabbix-release_3.4-1+stretch_all.deb
                        dpkg -i zabbix-release_3.4-1+stretch_all.deb
                        apt-get update && apt-get install -y zabbix-server-mysql zabbix-frontend-php mariadb-server
			systemctl enable mariadb
	
			config_zabbix_server
			logfile

		else
                        echo "Sorry, OS unknown"
                fi

	;;
################################### 0.08 OpenVPN ##################################
	6)
		if [ "$OS" = "CentOS7" ]; then
                        change_SE
			yum install ‐y epel-release
			yum install -y iptables-services openvpn easy-rsa

                else
                        echo ""
                        echo "Sorry, but it doesn't ready!"
                        echo ""
                fi
	;;
################################### 0.09 ???????????????? ##################################
	7)
                echo ""
                echo "Sorry, but it doesn't ready!"
                echo "" 
esac

exit 0
