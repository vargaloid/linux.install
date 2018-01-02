#!/usr/bin/env bash

###############################
# Installer by Varg. ver 0.04 #
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
echo "|3. zabbix-server                      |"
echo "|4. OpenVPN                            |"
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
		echo ""
                echo "Sorry, but it doesn't ready!"
                echo ""
        ;;
	4)
		echo ""
                echo "Sorry, but it doesn't ready!"
                echo ""        
esac
