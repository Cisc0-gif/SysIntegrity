 #! /bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
user=$(whoami)
currentdir=$(pwd)

wait_func() {
read -p "PRESS ENTER TO CONTINUE" wait
}

printf "${BLUE}[*] Checking if whitehash.list exists...${NC}\n"
if [ -f "/home/$user/.whitehash.list" ]; then
  printf "${GREEN}[+] Hash whitelist exists...${NC}\n"
else
  printf "${RED}[!] Unable to locate whitelist, generating...${NC}\n"
  touch /home/$user/.whitehash.list
  sudo chmod 700 /home/$user/.whitehash.list
  sudo chown $user /home/$user/.whitehash.list
fi

printf "${BLUE}[*] Checking if sysintegrity.log exists...${NC}\n"
if [ -f "/home/$user/.sysintegrity.log" ]; then
  printf "${GREEN}[+] Log exists...${NC}\n"
else
  printf "${RED}[!] Unable to locate log, generating...${NC}\n"
  touch /home/$user/.sysintegrity.log
  sudo chmod 700 /home/$user/.sysintegrity.log
fi

printf "${BLUE}[*] Checking if gtkhash is installed...${NC}\n"
gtkcheck=$(sudo dpkg -s gtkhash | grep not)
if [ -n "$gtkcheck" ]; then
  printf "${RED}[!] gtkhash not installed, installing now...${NC}\n"
  sudo apt-get install gtkhash
else
  printf "${GREEN}[+] gtkhash installed...${NC}\n"
fi
printf ${BLUE}
read -p "[*] Do you want to make a cronjob for verifying files on startup?[y/N]: " cronadd
printf ${NC}
if [ $cronadd == 'y' ] || [ $cronadd == 'Y' ]; then
  printf "${BLUE}[*] Adding cronjob...${NC}\n"
  echo $user | sudo tee -a /etc/cron.allow
  crontab -l | { cat; echo "@reboot bash -x $currentdir/cron.sh >> /home/$user/.sysintegrity.log"; } | crontab -
  printf "${GREEN}[+] Cronjob added, check /home/$user/.sysintegrity.log for output...${NC}\n"
else
  printf "${BLUE}[*] Cronjob skipped...${NC}\n"
fi
printf ${BLUE}
read -p "[*] Do you want to add any new files to whitelist?[y/N]: " newfiles
printf ${NC}
if [ $newfiles == 'y' ] || [ $newfiles == 'Y' ]; then
  printf "${BLUE}[*] Ex. /home/$user/Desktop/file.txt${NC}\n"
  printf "${BLUE}[*] Enter 'done' when finished${NC}\n"
  while [ 1 == 1 ]
  do
    read -p "[*] Filepath: " newfilepath
    if [ $newfilepath == 'done' ]; then
      break
    fi
    sudo md5sum $newfilepath >> /home/$user/.whitehash.list
  done
else
  printf "${BLUE}[*] Checking for whitelist matches...${NC}\n"
fi
count=$(wc -l /home/$user/.whitehash.list | awk '{ print $1 }')
printf "${BLUE}[*] Found $count entries...${NC}\n"
for i in $(seq 1 $count)
do
  match=$(awk '{if(NR=='$i') print $0}' /home/$user/.whitehash.list)
  hash=$(echo $match | awk '{ print $1 }')
  filepath=$(echo $match | awk '{ print $2 }')
  md5hash=$(sudo md5sum $filepath | awk '{ print $1 }')
  if [ $md5hash == $hash ]; then
   printf "${BLUE}[+] $filepath: ${GREEN}OK${NC}\n"
  else
    printf "${RED}[!] $filepath: ${RED}WARNING${NC}\n"
  fi
done
