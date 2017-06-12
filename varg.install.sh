#!/usr/bin/env bash

###############################
# Installer by Varg. ver 0.01 #
###############################

#Prisvaivaem peremennyuy usery ot kotorogo zapushen script
user=$(whoami)

#Proveryaem ot kogo zapushen script
if [[ $user == root ]]
 then
  echo "Hello! What do you want to install?";
 else
  echo "Hello $user, you have to be root to use this script";
  exit 0
fi

#Proveryaem OS
#OS=$(cat /etc/os-release | grep )

#Menu
exit 0
