#!/bin/bash

#check for sudo/root status
if [[ $(id -u) == 0 ]] #check for sudo or root status
then
  echo "Enter the domain you wish to join. ex: domain.com. \n"
  read domain
  echo "Enter a user account that can join the machine to the domain. \n"
  read user

  #install whats needed
  echo "Installing packages \n"
  apt-get update -y
  apt-get install realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir packagekit -y
  echo "Joining Domain \n"
  realm join $domain -U $user --install=/ --verbose

  #give domain users admin rights
  echo "Giving domain linux admins sudo rights"
  echo "#give AD admins sudo access" >> /etc/sudoers
  echo "%linux-admins@home.lab ALL=(ALL)   ALL" >> /etc/sudoers

  #enable home directory creation
  echo "Enable home directories for domain accounts"
  echo "Name: activate mkhomedir" > /usr/share/pam-configs/mkhomedir
  echo "Default: yes" >> /usr/share/pam-configs/mkhomedir
  echo "Priority: 900" >> /usr/share/pam-configs/mkhomedir
  echo "Session-Type: Additional" >> /usr/share/pam-configs/mkhomedir
  echo "Session:" >> /usr/share/pam-configs/mkhomedir
  echo "        required                        pam_mkhomedir.so umask=0022 skel=/etc/skel" >> /usr/share/pam-configs/mkhomedir

  pam-auth-update

  echo "If you received no warnings restart the computer to complete setup."
  exit 0

else
  echo "Error, run script with sudo or as root"
  exit 1
fi
