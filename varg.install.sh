#!/usr/bin/env bash

###############################
# Installer by Varg. ver 0.02 #
###############################

#check root
if [ "$(id -u)" != "0" ];  then
  echo ""
  echo " ===== Hello $(whoami)! You need to be root to run this script! ===== "
  echo ""
  exit 1
else
  echo " ==================== Hello $(whoami)! ===================="
  echo " *** This script works only on CentOS 7; Debian 8, Debian 9 ***"
  echo ""
fi

#check OS TYPE & VERSION
if [ -f /etc/redhat-release ]; then
	OS_RELEASE=$(cat /etc/redhat-release | awk '{print $1}')
	OS_VERSION=$(cat /etc/os-release | grep VERSION_ID | awk -F '\"' '{print $2}')
	if [ $OS_RELEASE == CentOS ] && [ $OS_VERSION == 7 ]; then
		OS="CentOS7"; echo $OS
	else
		echo "OS not supported!"
		exit 1
	fi
elif [ -f /etc/debian_version ]; then
	OS_RELEASE=$(lsb_release -c | awk '{print $2}')
	if [ $OS_RELEASE == jessie ]; then
		OS="Debian8"; echo "$OS $OS_RELEASE"
	elif [ $OS_RELEASE == stretch ]; then
                OS="Debian9"; echo "$OS $OS_RELEASE"
	else
		echo "OS not supported!"
                exit 1
	fi
else
	echo "OS Unknown"
	exit 1
fi

#Menu
echo "What do you want to install?"
exit 0
