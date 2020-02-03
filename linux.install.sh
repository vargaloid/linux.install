#!/usr/bin/env bash

########################################################
# Installer by https://github.com/vargaloid Ver.11.0.0 #
########################################################

Version='11.0.0'

C_BLUE='\033[36m'
C_RED='\033[31m'
C_GREEN='\033[32m'
C_DEF='\033[0m'
C_BOLD='\033[1m'
C_YEL='\e[33m'

############################ Log file #####################################
#exec 2>lin.inst.errors.log

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

################################### Check root ############################
if [ "$(id -u)" != "0" ];  then
  echo ""
  echo -en "$C_BLUE ===== Hello $(whoami)! You need to be root to run this script! ===== $C_DEF \n"
  echo ""
  exit 1
else
  echo ""
  echo -en "$C_BLUE ====================== Hello $(whoami)! ====================== $C_DEF \n"
  echo -en "$C_BLUE *************** The script version is $Version *************** $C_DEF \n"
fi

################################### Check OS TYPE & VERSION ###############
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
	Lsb_Release=$(lsb_release -c  | awk '{print $2}')
	if [[ $OS_RELEASE == '8' ]]; then
		OS="jessie"; echo -en "$C_BLUE ==================== Debian $OS_RELEASE $OS ==================== $C_DEF \n"
	elif [[ $OS_RELEASE == '9'  ]]; then
  		OS="stretch"; echo -en "$C_BLUE ==================== Debian $OS_RELEASE $OS ==================== $C_DEF \n"
	elif [[ $OS_RELEASE == '10' ]]; then
		OS="buster"; echo -en "$C_BLUE ==================== Debian $OS_RELEASE $OS ==================== $C_DEF \n"
	elif [[ $Lsb_Release == 'bionic' ]]; then
                OS="bionic"; echo -en "$C_BLUE ================= Ubuntu 18.04 $OS ================= $C_DEF \n"
	else
		echo -en "$C_RED OS not supported! $C_DEF \n"
    exit 1
	fi
else
	echo -en "$C_RED OS Unknown $C_DEF \n"
	exit 1
fi

################################### 1. Main Menu##############################
echo "----------------------------------------"
echo "|    What do you want to install?      |"
echo "----------------------------------------"
echo "|1. quit                               |"
echo "|2. mc,vim,sudo,wget,git               |"
echo "|3. vsftpd                             |"
echo "|4. fail2ban-ssh                       |"
echo "|5. zabbix-server 4.0                  |"
echo "|6. Docker                             |"
echo "|7. Proxmox VE5 (stretch), VE6 (buster)|"
echo "|8. MariaDB 10.3                       |"
echo "|9. GitLab CE                          |"
echo "|10. Jenkins                           |"
echo "|11. Prometheus with Grafana           |"
echo "----------------------------------------"

read MENU

case $MENU in
	1)
 		echo ""
		echo -en "$C_BLUE Bye! $C_DEF \n"
		echo ""
	;;
################################### 2. Utils installation ####################
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
################################### 3. vsftpd installation ###################
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
################################### 4. fail2ban-ssh ##########################
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
################################### 5. zabbix-server 4.0 #####################
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
	mysql -e "set global innodb_strict_mode='OFF';" ### Fix for version 4.0 and newiest MariaDB/MySQL
	zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u${z_s_username} -p${z_s_passwd} ${z_s_db_name}
	mysql -e "set global innodb_strict_mode='ON';" ### Fix  for version 4.0 and newiest MariaDB/MySQL

	echo -en "$C_BLUE \n"
	echo "Zabbix-server:"
	echo "DB name: ${z_s_db_name}"
	echo "DB username: ${z_s_username}"
	echo "DB password: ${z_s_passwd}"
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
	echo -en "$C_BLUE Continue to setup zabbix-server 4.0 accessing the web http://${host_ip}/zabbix $C_DEF \n"
	echo ""
}

### Zabbix-server process ###
AreYouSure
if [ "$OS" = "CentOS7" ]; then
	rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-2.el7.noarch.rpm
        yum install -y zabbix-server-mysql zabbix-web-mysql mariadb-server zabbix-agent
	systemctl start mariadb
	systemctl enable mariadb

	config_zabbix_server
	logfile

elif [ "$OS" = "jessie" ]; then
	wget https://repo.zabbix.com/zabbix/4.0/debian/pool/main/z/zabbix-release/zabbix-release_4.0-3+jessie_all.deb
	dpkg -i zabbix-release_4.0-3+jessie_all.deb
	apt-get update && apt-get install -y zabbix-server-mysql zabbix-frontend-php mariadb-server zabbix-agent
	systemctl enable mysql

	create_my.cnf
        config_zabbix_server
	logfile

elif [ "$OS" = "stretch" ]; then
        wget https://repo.zabbix.com/zabbix/4.0/debian/pool/main/z/zabbix-release/zabbix-release_4.0-3+stretch_all.deb 
        dpkg -i zabbix-release_4.0-3+stretch_all.deb 
        apt-get update && apt-get install -y zabbix-server-mysql zabbix-frontend-php mariadb-server zabbix-agent
	systemctl enable mariadb

	config_zabbix_server
	logfile

elif [ "$OS" = "buster" ]; then
        wget https://repo.zabbix.com/zabbix/4.0/debian/pool/main/z/zabbix-release/zabbix-release_4.0-3+buster_all.deb 
        dpkg -i zabbix-release_4.0-3+buster_all.deb 
        apt-get update && apt-get install -y zabbix-server-mysql zabbix-frontend-php mariadb-server zabbix-agent
        systemctl enable mariadb

        config_zabbix_server
        logfile

else
        echo "Sorry, OS unknown"
fi

;;
################################### 6. Docker ################################
	6)
### Docker function ###
DockerStart () {
 systemctl start docker.service
 systemctl enable docker.service
 systemctl status docker.service
}
DockerComposeInstall () {
 curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
 chmod +x /usr/local/bin/docker-compose
 ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
}
### End Docker function ###
		AreYouSure
		if [ "$OS" = "CentOS7" ]; then
			yum install -y yum-utils device-mapper-persistent-data lvm2
			yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
			yum install -y docker-ce
			DockerComposeInstall
			DockerStart
			logfile
		elif [[ $OS == "jessie" || $OS == "stretch" ]]; then
			apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
			curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
			apt-key fingerprint 0EBFCD88
			add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
			apt-get update
			apt-get install -y docker-ce
			DockerComposeInstall
			DockerStart
			logfile
                else
                        echo ""
                        echo "Sorry, your OS is not supported"
                        echo ""
                fi
	;;
################################### 7. Proxmox VE installation ###############
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
elif [ "$OS" = "buster"]; then
	echo "$(hostname -I) $(hostname) pvelocalhost" >> /etc/hosts
        echo "deb http://download.proxmox.com/debian/pve buster pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
	wget http://download.proxmox.com/debian/proxmox-ve-release-6.x.gpg -O /etc/apt/trusted.gpg.d/proxmox-ve-release-6.x.gpg
	chmod +r /etc/apt/trusted.gpg.d/proxmox-ve-release-6.x.gpg
	apt update && apt full-upgrade -y
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
################################### 8. MariaDB 10.3 install #################
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
################################### 9. GitLab CE installation ###############
9)
AreYouSure
if [ "$OS" = "CentOS7" ]; then
	yum install -y curl policycoreutils-python openssh-server
	systemctl enable sshd
	systemctl start sshd
	firewall-cmd --permanent --add-service=http
	firewall-cmd --permanent --add-service=https
	systemctl reload firewalld
	yum install postfix
	systemctl enable postfix
	systemctl start postfix
	curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | bash
	echo ""
        echo -e "$C_GREEN Please, enter external_url for GitLab project. Example:$C_DEF $C_YEL http://gitlab.example.com $C_DEF"
        echo ""
        read Ext_Url
        EXTERNAL_URL="${Ext_Url}" yum install -y gitlab-ce 
        echo ""
        echo -e "$C_GREEN Please, visit ${Ext_Url} to finish installation $C_DEF"
        echo ""
        logfile
elif [ "$OS" = "jessie" ]; then
	echo -e "$C_RED Sorry, Debian 8 is not supported $C_DEF"
        logfile
elif [ "$OS" = "stretch" || "$OS" = "buster" ]; then
	dpkg-reconfigure locales
	apt-get update
	apt-get install -y sudo openssh-server ca-certificates postfix curl
	curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash
	echo ""
	echo -e "$C_GREEN Please, enter external_url for GitLab project. Example:$C_DEF $C_YEL http://gitlab.example.com $C_DEF"
	echo ""
	read Ext_Url
	EXTERNAL_URL="${Ext_Url}" apt-get install gitlab-ce
	echo ""
	echo -e "$C_GREEN Please, visit ${Ext_Url} to finish installation $C_DEF"
	echo ""
        logfile
else
        echo -e "$C_RED Sorry, OS unknown $C_DEF"
	logfile
fi
;;
###################################### 10. jenkins #############################
10)
AreYouSure
if [ "$OS" = "CentOS7" ]; then
	yum install -y wget java
	wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
	rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
	yum install -y jenkins
	firewall-cmd --permanent --zone=public --add-port=8080/tcp
	firewall-cmd --reload
	service jenkins start
	chkconfig jenkins on
	host_ip=$(hostname -I | sed s/' '//)
        echo ""
        echo -en "$C_BLUE Continue to setup jenkins accessing the web http://${host_ip}:8080 $C_DEF \n"
        echo ""

        logfile
elif [[ "$OS" = "stretch" || "$OS" = "buster" ]]; then
	dpkg-reconfigure locales
	apt-get update && apt-get install -y apt-transport-https default-jre gnupg2
	wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | apt-key add -
	sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
	apt-get update && apt-get install -y jenkins
	host_ip=$(hostname -I | sed s/' '//)
        echo ""
	echo -en "$C_BLUE Continue to setup jenkins accessing the web http://${host_ip}:8080 $C_DEF \n"
        echo ""


	logfile
else
	echo -e "$C_RED Sorry, OS not supported $C_DEF"
	logfile
fi
;;
############################## 11. Prometheus ###############################################
11)

#========== Variables ==========#
PrometheusVersion='2.15.2'
AlertmanagerVersion='0.20.0'
GrafanaVersion='6.6.0'
host_ip=$(hostname -I | sed s/' '//)
#========== Prometheus function =============#
PromInst () {
# Download Prometheus and install
	rm -rf /tmp/prometheus*
	wget -P /tmp/ https://github.com/prometheus/prometheus/releases/download/v${PrometheusVersion}/prometheus-${PrometheusVersion}.linux-amd64.tar.gz
	mkdir /etc/prometheus /var/lib/prometheus
	tar zxvf /tmp/prometheus-*.linux-amd64.tar.gz -C /tmp/
	cp /tmp/prometheus-*.linux-amd64/prometheus /tmp/prometheus-*.linux-amd64/promtool /usr/local/bin/
	cp -r /tmp/prometheus-*.linux-amd64/console_libraries /tmp/prometheus-*.linux-amd64/consoles /tmp/prometheus-*.linux-amd64/prometheus.yml /etc/prometheus
	useradd --no-create-home --shell /bin/false prometheus
	chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
	chown prometheus:prometheus /usr/local/bin/{prometheus,promtool}
# create systemd service
cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus Service
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path /var/lib/prometheus/ \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable prometheus
chown -R prometheus:prometheus /var/lib/prometheus
systemctl start prometheus

}
#========== AlertManager function =============#
AlManInst () {

# Download and install Alertmanager
rm -rf /tmp/alertmanager*
wget -P /tmp/ https://github.com/prometheus/alertmanager/releases/download/v${AlertmanagerVersion}/alertmanager-${AlertmanagerVersion}.linux-amd64.tar.gz
mkdir /etc/alertmanager /var/lib/prometheus/alertmanager
tar zxvf /tmp/alertmanager-*.linux-amd64.tar.gz -C /tmp/
cp /tmp/alertmanager-*.linux-amd64/alertmanager /tmp/alertmanager-*.linux-amd64/amtool /usr/local/bin/
cp /tmp/alertmanager-*.linux-amd64/alertmanager.yml /etc/alertmanager
useradd --no-create-home --shell /bin/false alertmanager
chown -R alertmanager:alertmanager /etc/alertmanager /var/lib/prometheus/alertmanager
chown alertmanager:alertmanager /usr/local/bin/{alertmanager,amtool}
# create systemd service
cat > /etc/systemd/system/alertmanager.service <<EOF
[Unit]
Description=Alertmanager Service
After=network.target

[Service]
EnvironmentFile=-/etc/default/alertmanager
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
          --config.file=/etc/alertmanager/alertmanager.yml \
          --storage.path=/var/lib/prometheus/alertmanager \
          $ALERTMANAGER_OPTS
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable alertmanager
systemctl start alertmanager
}
#========== Grafana function =============#
GrafanaInst (){
systemctl start grafana-server
systemctl status grafana-server
systemctl enable grafana-server
}
#==========================================#

AreYouSure
if [ "$OS" = "CentOS7" ]; then
	yum install -y wget
	PromInst
	AlManInst
	wget -P /tmp/ https://dl.grafana.com/oss/release/grafana-${GrafanaVersion}-1.x86_64.rpm
	yum localinstall -y /tmp/grafana-*.x86_64.rpm
	GrafanaInst
	echo ""
        echo -en "$C_BLUE Continue to setup accessing the web http://${host_ip}:3000 $C_DEF \n"
        echo ""

elif [[ "$OS" = "stretch" || "$OS" = "buster" ]]; then
	dpkg-reconfigure locales
	PromInst
	AlManInst
	apt-get update && apt-get install -y adduser libfontconfig1
	wget -P /tmp/ https://dl.grafana.com/oss/release/grafana_${GrafanaVersion}_amd64.deb
	dpkg -i /tmp/grafana_*_amd64.deb
	GrafanaInst
	echo ""
        echo -en "$C_BLUE Continue to setup accessing the web http://${host_ip}:3000 $C_DEF \n"
        echo ""

elif [[ "$OS" = "bionic" ]]; then
	PromInst
	AlManInst
	apt-get update && apt-get install -y adduser libfontconfig1
	wget -P /tmp/ https://dl.grafana.com/oss/release/grafana_${GrafanaVersion}_amd64.deb
	dpkg -i /tmp/grafana_*_amd64.deb
	GrafanaInst
	echo ""
        echo -en "$C_BLUE Continue to setup accessing the web http://${host_ip}:3000 $C_DEF \n"
        echo ""

else
	echo -e "$C_RED Sorry, OS not supported $C_DEF"
fi


esac

exit 0
