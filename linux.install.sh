#!/usr/bin/env bash

################################
# Installer by Varg. ver 11.02 #
################################

C_BLUE='\033[36m'
C_RED='\033[31m'
C_GREEN='\033[32m'
C_DEF='\033[0m'
C_BOLD='\033[1m'
C_YEL='\e[33m'

############################ 0.00 Log file #####################################
exec 2>lin.inst.errors.log

############################ FUNCTIONS #########################################
### Log Func ###
logfile () {

echo ""
echo -en "$C_GREEN Do you want to see error log? (y/N) $C_DEF"
echo ""

read LOGFILE

case $LOGFILE in
Y|y)
	less lin.inst.errors.log
	;;
*)
	exit 0
esac

}

### AreYouSure function ###
AreYouSure () {
echo -n "Do you really want to select this? (N/y): "
read -n 1 AMSure
case "$AMSure" in
    y|Y) echo ""
	 echo "Ok! Let's do it!..."
	 echo ""
        ;;
    *)   echo ""
	 echo "Bye! :)"
	 echo ""
        exit 0
        ;;
esac
}

### SELINUX Permissive function ###
change_SE () {
        setenforce Permissive
        sed -i "/SELINUX=enforcing/c SELINUX=permissive" /etc/selinux/config
}

### Create .my.cnf function ###
create_my.cnf () {
	echo ""
	echo -en "$C_BLUE Create .my.cnf $C_DEF \n"
	echo -en "$C_GREEN Please, repeat password for MariaDB: $C_DEF \n"
	echo ""
	read MDB_PASS
	echo "[client]" > /root/.my.cnf
	echo "password = $MDB_PASS" >> /root/.my.cnf
}

################################### 1.01 Check root ############################
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

################################### 2.01 Check OS TYPE & VERSION ###############
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
	OS_RELEASE=$(cat /etc/debian_version | awk -F . '{print $1}')
	if [[ $OS_RELEASE == '8' ]]; then
		OS="jessie"; echo -en "$C_BLUE ======= $OS $OS_RELEASE ======= $C_DEF \n"
	elif [[ $OS_RELEASE == '9'  ]]; then
  	OS="stretch"; echo -en "$C_BLUE ======= $OS $OS_RELEASE ======= $C_DEF \n"
	else
		echo -en "$C_RED OS not supported! $C_DEF \n"
    exit 1
	fi
else
	echo -en "$C_RED OS Unknown $C_DEF \n"
	exit 1
fi

################################### 3.01 Main Menu##############################
echo "----------------------------------------"
echo "|    What do you want to install?      |"
echo "----------------------------------------"
echo "|1. exit                               |"
echo "|2. mc,vim,sudo,wget,git               |"
echo "|3. vsftpd                             |"
echo "|4. fail2ban-ssh                       |"
echo "|5. zabbix-server 3.4                  |"
echo "|6. Docker                             |"
echo "|7. Proxmox VE (Only for Debian 9!)    |"
echo "|8. MariaDB 10.3                       |"
echo "|9. GitLab CE (Only for Debian 9!)     |"
echo "----------------------------------------"

read MENU

case $MENU in
	1)
 		echo ""
		echo -en "$C_BLUE Bye! $C_DEF \n"
		echo ""
	;;
################################### 4.01 Utils installation ####################
	2)
		AreYouSure
		if [ "$OS" = "CentOS7" ]; then
			yum install mc vim sudo wget git -y
			logfile
		else
			apt-get update
			apt-get install -y mc vim sudo wget git
			logfile
		fi
	;;
################################### 5.01 vsftpd installation ###################
	3)
### Vsftpd installation function ###
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

### vsftpd proccess ###
		AreYouSure
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
################################### 6.01 fail2ban-ssh ##########################
  4)

		AreYouSure
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

[sshd]
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
################################### 7.01 zabbix-server 3.4 #####################
	5)
### Zabbix-server setup function ###
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

### Zabbix-server process ###
		AreYouSure
		if [ "$OS" = "CentOS7" ]; then
			rpm -ivh http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-1.el7.centos.noarch.rpm
                        yum install -y zabbix-server-mysql zabbix-web-mysql mariadb-server
			systemctl start mariadb
		        systemctl enable mariadb

			config_zabbix_server
			logfile

		elif [ "$OS" = "jessie" ]; then
			wget http://repo.zabbix.com/zabbix/3.4/debian/pool/main/z/zabbix-release/zabbix-release_3.4-1+jessie_all.deb
			dpkg -i zabbix-release_3.4-1+jessie_all.deb
			apt-get update && apt-get install -y zabbix-server-mysql zabbix-frontend-php mariadb-server
			systemctl enable mysql

			create_my.cnf
                        config_zabbix_server
			logfile

		elif [ "$OS" = "stretch" ]; then
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
################################### 8.02 Docker ################################
	6)
### Docker function ###
DockerStart () {
systemctl start docker.service
systemctl enable docker.service
systemctl status docker.service
}
### End Docker function ###
		AreYouSure
		if [ "$OS" = "CentOS7" ]; then
			yum install -y yum-utils device-mapper-persistent-data lvm2
			yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
			yum install -y docker-ce
			DockerStart
			logfile
		elif [[ $OS == "jessie" || $OS == "stretch" ]]; then
			apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
			curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
			apt-key fingerprint 0EBFCD88
			add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
			apt-get update
			apt-get install -y docker-ce
			DockerStart
			logfile
                else
                        echo ""
                        echo "Sorry, your OS is not supported"
                        echo ""
                fi
	;;
################################### 9.02 Proxmox VE installation ###############
	7)
		AreYouSure
		if [ "$OS" = "stretch" ]; then
			echo "$(hostname -I) $(hostname) pvelocalhost" >> /etc/hosts
			echo "deb http://download.proxmox.com/debian/pve stretch pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
			wget http://download.proxmox.com/debian/proxmox-ve-release-5.x.gpg -O /etc/apt/trusted.gpg.d/proxmox-ve-release-5.x.gpg
			apt-get update && apt-get install -y proxmox-ve postfix open-iscsi
			apt-get remove -y os-prober
			echo ""
			echo -en "$C_BLUE Please, reboot your system and check your kernel $C_DEF \n"
      echo ""
			logfile
		else
			echo ""
      echo "Sorry, but it doesn't ready!"
			echo ""
		fi
	;;
################################### 10.02 MariaDB 10.3 install #################
	8)
		AreYouSure
                if [ "$OS" = "CentOS7" ]; then
cat >  /etc/yum.repos.d/MariaDB.repo <<EOF
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
			yum install -y MariaDB-server MariaDB-client
			systemctl start mysql
                        logfile

                elif [ "$OS" = "jessie" ]; then
cat >  /etc/apt/sources.list.d/MariaDB.list <<EOF
# http://downloads.mariadb.org/mariadb/repositories/
deb [arch=amd64,i386] http://mirror.klaus-uwe.me/mariadb/repo/10.3/debian jessie main
deb-src http://mirror.klaus-uwe.me/mariadb/repo/10.3/debian jessie main
EOF
			apt-get install apt-transport-https ca-certificates -y --force-yes
                        apt-get update
                        apt-get install mariadb-server -y --force-yes
			logfile

                elif [ "$OS" = "stretch" ]; then
cat >  /etc/apt/sources.list.d/MariaDB.list <<EOF
# http://downloads.mariadb.org/mariadb/repositories/
deb [arch=amd64,i386,ppc64el] http://mirror.klaus-uwe.me/mariadb/repo/10.3/debian stretch main
deb-src http://mirror.klaus-uwe.me/mariadb/repo/10.3/debian stretch main
EOF
			apt-get install apt-transport-https ca-certificates -y --force-yes
                        apt-get update
                        apt-get install mariadb-server -y --force-yes
                        logfile
		else
                        echo "Sorry, OS unknown"
                fi

        ;;
################################### 11.00 GitHub CE installation ###############
	9)
			AreYouSure
      if [ "$OS" = "CentOS7" ]; then
				echo -e "$C_RED Sorry, CentOS 7 is not supported $C_DEF"
        logfile

      elif [ "$OS" = "jessie" ]; then
				echo -e "$C_RED Sorry, Debian 8 is not supported $C_DEF"
        logfile

      elif [ "$OS" = "stretch" ]; then
				dpkg-reconfigure locales
				apt-get update
				apt-get install -y sudo openssh-server ca-certificates postfix curl
				curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash
				echo ""
				echo -e "$C_GREEN Please, enter external_url for GitLab project. Example:$C_DEF $C_YEL http://gitlab.example.com $C_DEF"
				echo ""
				read Ext_Url
				EXTERNAL_URL="http://${Ext_Url}" apt-get install gitlab-ce
				echo ""
				echo -e "$C_GREEN Please, visit http://${Ext_Url} to finish installation $C_DEF"
				echo ""
        logfile

      else
        echo -e "$C_RED Sorry, OS unknown $C_DEF"
				logfile
      fi

esac

exit 0
