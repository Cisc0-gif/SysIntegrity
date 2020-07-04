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

printf "${BLUE}[*] Checking if whitehost.list exists...${NC}\n"
if [ -f "/home/$user/.whitehost.list" ]; then
  printf "${GREEN}[+] Host whitelist exists...${NC}\n"
else
  printf "${RED}[!] Unable to locate whitelist, generating...${NC}\n"
  touch /home/$user/.whitehost.list
  sudo chmod 700 /home/$user/.whitehost.list
  sudo chown $user /home/$user/.whitehost.list
fi

printf "${BLUE}[*] Checking if .authips.list exists...${NC}\n"
if [ -f "/home/$user/.authips.list" ]; then
  printf "${GREEN}[+] Auth Log list exists...${NC}\n"
else
  printf "${RED}[!] Unable to locate auth log list, generating...${NC}\n"
  sudo cat /var/log/auth.log | grep -Po "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq > /home/$user/.authips.list
  sudo chmod 700 /home/$user/.authips.list
  sudo chown $user /home/$user/.authips.list
fi

printf "${BLUE}[*] Checking if sysintegrity.log exists...${NC}\n"
if [ -f "/home/$user/.sysintegrity.log" ]; then
  printf "${GREEN}[+] Log exists...${NC}\n"
else
  printf "${RED}[!] Unable to locate log, generating...${NC}\n"
  touch /home/$user/.sysintegrity.log
  sudo chmod 700 /home/$user/.sysintegrity.log
fi

printf "${BLUE}[*] Checking if ufw is installed...${NC}\n"
ufwcheck=$(sudo dpkg -s ufw | grep not)
if [ -n "$ufwcheck" ]; then
  printf "${RED}[!] ufw not installed, installing now...${NC}\n"
  sudo apt-get install ufw
else
  printf "${GREEN}[+] ufw installed...${NC}\n"
fi

printf "${BLUE}[*] Checking if rkhunter is installed...${NC}\n"
rkhuntercheck=$(sudo dpkg -s rkhunter | grep dpkg-query)
if [ -n "$rkhuntercheck" ]; then
  printf "${RED}[!] rkhunter not installed, installing now...${NC}\n"
  sudo apt-get install rkhunter
else
  printf "${GREEN}[+] rkhunter installed...${NC}\n"
fi

printf "${BLUE}[*] Checking if gtkhash is installed...${NC}\n"
gtkcheck=$(sudo dpkg -s gtkhash | grep not)
if [ -n "$gtkcheck" ]; then
  printf "${RED}[!] gtkhash not installed, installing now...${NC}\n"
  sudo apt-get install gtkhash
else
  printf "${GREEN}[+] gtkhash installed...${NC}\n"
fi

printf "${BLUE}\n"
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
printf "${BLUE}\n"
read -p "[*] Do you want to add any new files to whitelist?[y/N]: " newfiles
printf ${NC}
if [ $newfiles == 'y' ] || [ $newfiles == 'Y' ]; then
  printf "${BLUE}[*] Ex. /home/$user/Desktop/file.txt${NC}\n"
  printf "${BLUE}[*] Enter 'done' when finished${NC}\n"
  while [ 1 == 1 ]; do
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
printf "${BLUE}\n"
read -p "[*] Do you want to add any new IPs to whitelist?[y/N]: " newips
printf "${NC}"
if [ $newips == 'y' ] || [ $newips == 'Y' ]; then
  printf "${BLUE}[*] Ex. 192.168.1.0${NC}\n"
  printf "${BLUE}[*] Enter 'done' when finished${NC}\n"
  while [ 1 == 1 ]; do
    read -p "[*]IP: " newip
    if [ $newip == 'done' ]; then
      break
    fi
    echo "$newip" >> /home/$user/.whitehost.list
  done
else
  printf "\n${BLUE}[*] Checking for nonapproved IPs in auth.log\n"
fi
printf "${BLUE}[*] Refreshing .authips.list...${NC}\n"
sudo cat /var/log/auth.log | grep -Po "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq > /home/$user/.authips.list
ipcount=$(wc -l /home/$user/.whitehost.list | awk '{ print $1 }')
authcount=$(wc -l /home/$user/.authips.list | awk '{ print $1 }')
printf "${BLUE}[*] Found $ipcount entries...${NC}\n"
warningmessages=$(sudo grep "Warning:" /var/log/rkhunter.log.1 | sort)
if [ -z "$warningmessages" ]; then
  printf "${GREEN}[+] No warning messages detected!${NC}\n"
else
  printf "${RED}[!] Found warning messages with the following issues${NC}\n"
  printf "$warningmessages\n"
fi
ufwblocked=$(sudo grep "[UFW BLOCK]" /var/log/ufw.log | grep -Po "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq -c | awk '{ print $2 }')
if [ -z "$ufwblocked" ]; then
  printf "${GREEN}[+] No block requests detected!${NC}\n"
else
  printf "${RED}[!] Found blocked requests from the following IPs: ${NC}\n"
  printf "$ufwblocked\n"
fi
failedlogin=$(sudo grep "Failed password for" /var/log/auth.log | grep -Po "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq -c | awk '{ print $2 }')
if [ -z "$failedlogin" ]; then
  printf "${GREEN}[+] No failed-login attempts detected!${NC}\n"
else
  printf "${RED}[!] Found failed-login attempts from the following IPs: ${NC}\n"
  printf "$failedlogin"
fi
iparray=()
autharray=()
for i in $(seq 1 $ipcount); do
  ipmatch=$(awk '{if(NR=='$i') print $0}' /home/$user/.whitehost.list)
  iparray+=("$ipmatch")
done
for i in $(seq 1 $authcount); do
  authipmatch=$(awk '{if(NR=='$i') print $0}' /home/$user/.authips.list)
  autharray+=("$authipmatch")
done
unauthips=()
for i in "${autharray[@]}"; do
  skip=
  for j in "${iparray[@]}"; do
    [[ $i == $j ]] && { skip=1; break; }
  done
  [[ -n $skip ]] || unauthips+=("$i")
done
unapproved=$(echo ${unauthips[@]})
if [ -z "$unapproved" ]; then
  printf "${GREEN}[+] No unapproved IPs in auth.log${NC}\n"
else
  printf "${RED}[!] Unapproved IPs found in auth.log: ${NC}\n"
  for i in "${unauthips[@]}"; do
    printf "$i\n"
  done
fi
#WORK_HERE
