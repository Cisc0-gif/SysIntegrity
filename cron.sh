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
for i in $(seq 1 $count); do
  match=$(awk '{if(NR=='$i') print $0}' /home/$user/.whitehash.list)
  hash=$(echo $match | awk '{ print $1 }')
  filepath=$(echo $match | awk '{ print $2 }')
  md5hash=$(md5sum $filepath | awk '{ print $1 }')
  if [ $md5hash == $hash ]; then
   printf "${BLUE}[+] $filepath: ${GREEN}OK--$timestamp${NC}\n"
  else
    printf "${RED}[!] $filepath: ${RED}WARNING--$timestamp${NC}\n"
  fi
done
printf "${BLUE}[*] Checking for nonapproved IPs in auth.log...\n"
printf "${BLUE}[*] Refreshing .authips.list...${NC}\n"
sudo cat /var/log/auth.log | grep -Po "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq > /home/$user/.authips.list
ipcount=$(wc -l /home/$user/.whitehost.list | awk '{ print $1 }')
authcount=$(wc -l /home/$user/.authips.list | awk '{ print $1 }')
printf "${BLUE}[*] Found $ipcount entries...${NC}\n"
failedlogin=$(sudo grep "Failed password for" /var/log/auth.log | grep -Po "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq -c | awk '{ print $2 }')
if [ -z "$failedlogin" ]; then
  printf "${GREEN}[+] No failed-login attempts detected!--$timestamp${NC}\n"
else
  printf "${RED}[!] Found failed-login attempts from the following IPs: --$timestamp${NC}\n"
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
  printf "${GREEN}[+] No unapproved IPs in auth.log--$timestamp${NC}\n"
else
  printf "${RED}[!] Unapproved IPs found in auth.log: ${NC}\n"
  for i in "${unauthips[@]}"; do
    printf "${RED}  $i  --$timestamp\n"
  done
fi
