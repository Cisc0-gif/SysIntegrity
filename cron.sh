 #! /bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
user=$(whoami)
timestamp=$(date)

wait_func() {
read -p "PRESS ENTER TO CONTINUE" wait
}

printf "${BLUE}[*] Checking if whitehash.list exists...--$timestamp${NC}\n"
if [ -f "/home/$user/.whitehash.list" ]; then
  printf "${GREEN}[+] Hash whitelist exists...--$timestamp${NC}\n"
else
  printf "${RED}[!] Unable to locate whitelist, generating...--$timestamp${NC}\n"
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
gtkcheck=$(dpkg -s gtkhash | grep not)
if [ -n "$gtkcheck" ]; then
  printf "${RED}[!] gtkhash not installed, installing now...${NC}\n"
  sudo apt-get install gtkhash
else
  printf "${GREEN}[+] gtkhash installed...${NC}\n"
fi

printf "${BLUE}[*] Checking for whitelist matches...${NC}\n"
count=$(wc -l /home/$user/.whitehash.list | awk '{ print $1 }')
printf "${BLUE}[*] Found $count entries...--$timestamp${NC}\n"
for i in $(seq 1 $count)
do
  match=$(awk '{if(NR=='$i') print $0}' /home/$user/.whitehash.list)
  hash=$(echo $match | awk '{ print $1 }')
  filepath=$(echo $match | awk '{ print $2 }')
  md5hash=$(sudo md5sum $filepath | awk '{ print $1 }')
  if [ $md5hash == $hash ]; then
   printf "${BLUE}[+] $filepath: ${GREEN}OK--$timestamp{NC}\n"
  else
    printf "${RED}[!] $filepath: ${RED}WARNING--$timestamp${NC}\n"
  fi
done
