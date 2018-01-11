#!/usr/bin/env bash

###############################
# Installer by Varg. ver 0.05 #
###############################

# Check root
if [ "$(id -u)" != "0" ];  then
  echo ""
  echo " ===== Hello $(whoami)! You need to be root to run this script! ===== "
  echo ""
  exit 1
else
  echo ""
  echo " ====================== Hello $(whoami)! ======================"
  echo " *** This script works only on CentOS 7; Debian 8, Debian 9 ***"
  echo ""
fi

# Check OS TYPE & VERSION
if [ -f /etc/redhat-release ]; then
	OS_RELEASE=$(cat /etc/redhat-release | awk '{print $1}')
	OS_VERSION=$(cat /etc/os-release | grep VERSION_ID | awk -F '\"' '{print $2}')
	if [ $OS_RELEASE == CentOS ] && [ $OS_VERSION == 7 ]; then
		OS="CentOS7"; echo " ========== $OS ========== "
	else
		echo "OS not supported!"
		exit 1
	fi
elif [ -f /etc/debian_version ]; then
	OS_RELEASE=$(lsb_release -c | awk '{print $2}')
	if [ $OS_RELEASE == jessie ]; then
		OS="Debian8"; echo " ======= $OS $OS_RELEASE ======= "
	elif [ $OS_RELEASE == stretch ]; then
                OS="Debian9"; echo " ======= $OS $OS_RELEASE ======= "
	else
		echo "OS not supported!"
                exit 1
	fi
else
	echo "OS Unknown"
	exit 1
fi

# Main Menu
echo "----------------------------------------"
echo "|    What do you want to install?      |"
echo "----------------------------------------"
echo "|1. exit                               |"
echo "|2. mc,vim,sudo,wget,net-tools,git     |"
echo "|3. vsftpd                             |"
echo "|4. zabbix-server                      |"
echo "|5. OpenVPN                            |"
echo "----------------------------------------"

read MENU

case $MENU in
	1)
 		echo ""
		echo " Bye! "
		echo ""
		exit 0
	;;
	2)
		if [ "$OS" = "CentOS7" ]; then
			yum install mc vim sudo wget net-tools git -y
		else
			apt-get update
			apt-get install -y mc vim sudo wget net-tools git
		fi
	;;
	3)

config_vsftpd() {
cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.orig
cp /dev/null/ /etc/vsftpd/vsftpd.conf
cat > /etc/vsftpd/vsftpd.conf <<EOF
anonymous_enable = NO
local_enable = YES
write_enable = YES
local_umask = 022
dirmessage_enable = YES
xferlog_enable = YES
xferlog_std_format = YES
connect_from_port = YES
listen = YES
listen_ipv6 = NO
pam_service_name = vsftpd
userlist_enable = YES
userlist_file=/etc/vsftpd/vsftpd.userlist
userlist_deny = NO
chroot_local_user = YES
allow_writable_chroot = YES
tcp_wrappers = YES
ftpd_banner = Welcome to FTP service.
idle_session_timeout = 600
data_connection_timeout = 120
EOF

echo ""
echo "Do you want to add new ftp user? (yes or no)"
echo ""

case $NEWFTPUSER in
yes | y)
	echo ""
	echo "Please enter username" 
	echo ""
	read FTPUSER
	echo ""
        echo "Please enter password for user $FTPUSER" 
        echo ""
        read FTPPASS
	echo ""
        echo "Please enter home directory for user $FTPUSER" 
        echo ""
        read FTPHOME
	
	useradd -s /bin/bash -p $FTPPASS -d $FTPHOME -m $FTPUSER
;;
*)
esac

systemctl restart vsftpd
systemctl enable vsftpd

echo ""
echo "vsftpd was successfully installed"
echo ""
if [ "$NEWFTPUSER" = "yes" || "$NEWFTPUSER" = "y" ]; then 
	echo "User $FTPUSER was successfully added"
	echo ""
else
fi
echo "Please don't forget add firewall rules for ftp! Have a nice day!" 
echo ""
netstat -tulpn | grep ftp
echo ""

}
		if [ "$OS" = "CentOS7" ]; then
                        yum install -y vsftpd
			config_vsftpd
                else
                        apt-get update
                        apt-get install -y vsftpd
			config_vsftpd
                fi
        ;;
	4)
		echo ""
                echo "Sorry, but it doesn't ready!"
                echo ""
	;;
	5)
		echo ""
		echo "Sorry, but it doesn't ready!"
		echo "" 
esac

exit 0
