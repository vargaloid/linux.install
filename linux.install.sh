#!/usr/bin/env bash

###############################
# Installer by Varg. ver 0.05 #
###############################

################################### 0.01 Check root ##############################
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

################################### 0.02 Check OS TYPE & VERSION #################
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

################################### 0.03 Main Menu##################################
echo "----------------------------------------"
echo "|    What do you want to install?      |"
echo "----------------------------------------"
echo "|1. exit                               |"
echo "|2. mc,vim,sudo,wget,net-tools,git     |"
echo "|3. vsftpd                             |"
echo "|4. fail2ban-ssh                       |"
echo "|5. zabbix-server                      |"
echo "|6. OpenVPN                            |"
echo "|7. Proxmox (Only for Debian!)         |"
echo "----------------------------------------"

read MENU

case $MENU in
	1)
 		echo ""
		echo " Bye! "
		echo ""
		exit 0
	;;
################################### 0.04 Utils installation #########################
	2)
		if [ "$OS" = "CentOS7" ]; then
			yum install mc vim sudo wget net-tools git -y
		else
			apt-get update
			apt-get install -y mc vim sudo wget net-tools git
		fi
	;;
################################### 0.05 vsftpd installation ########################
	3)

DEBVSFTPD=/etc
CENTOSVSFTPD=/etc/vsftpd

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
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=YES
pam_service_name=vsftpd
userlist_enable=YES
userlist_file=/etc/vsftpd/vsftpd.userlist
userlist_deny=NO
chroot_local_user=YES
allow_writeable_chroot=YES
tcp_wrappers=YES
EOF

touch $OSVSFTPD/vsftpd.userlist

echo ""
echo "Do you want to add new ftp user? (yes or no)"
echo ""

read NEWFTPUSER

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
        echo "Please enter home directory for user $FTPUSER (example:/home/$FTPUSER)" 
        echo ""
        read FTPHOME
	
	useradd -s /sbin/nologin -p $FTPPASS -d $FTPHOME -m $FTPUSER
	echo "$FTPUSER" | tee -a $OSVSFTPD/vsftpd.userlist
;;
*)
esac

systemctl restart vsftpd
systemctl enable vsftpd

echo ""
echo "vsftpd was successfully installed"
echo ""
if [[ "$NEWFTPUSER" = "yes" || "$NEWFTPUSER" = "y" ]]; then 
	echo "User $FTPUSER was successfully added"
	echo ""
else
	echo ""
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
################################### 0.06 fail2ban-ssh ###############################
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
