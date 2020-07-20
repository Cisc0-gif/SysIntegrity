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

printf "${BLUE}[*] Checking if .whiteuser.list exists...${NC}\n"
if [ -f "/home/$user/.whiteuser.list" ]; then
  printf "${GREEN}[+] User Whitelist exists...${NC}\n"
else
  printf "${RED}[!] Unable to locate whitelist, generating...${NC}\n"
  touch /home/$user/.whiteuser.list
  sudo chmod 700 /home/$user/.whiteuser.list
  sudo chown $user /home/$user/.whiteuser.list
fi

printf "${BLUE}[*] Checking if .whitegroup.list exists...${NC}\n"
if [ -f "/home/$user/.whitegroup.list" ]; then
  printf "${GREEN}[+] User Whitelist exists...${NC}\n"
else
  printf "${RED}[!] Unable to locate whitelist, generating...${NC}\n"
  touch /home/$user/.whitegroup.list
  sudo chmod 700 /home/$user/.whitegroup.list
  sudo chown $user /home/$user/.whitegroup.list
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
    printf "${RED}[!] $filepath: WARNING--$timestamp${NC}\n"
  fi
done

printf "${BLUE}[*] Refreshing .authips.list...${NC}\n"
sudo cat /var/log/auth.log | grep -Po "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq > /home/$user/.authips.list
ipcount=$(wc -l /home/$user/.whitehost.list | awk '{ print $1 }')
authcount=$(wc -l /home/$user/.authips.list | awk '{ print $1 }')

warningmessages=$(sudo grep "Warning:" /var/log/rkhunter.log.1 | sort)
if [ -z "$warningmessages" ]; then
  printf "${BLUE}[+] rkhunter.1.log: ${GREEN}OK --$timestamp${NC}\n"
else
  printf "${RED}[!] rkhunter.1.log: Found warning messages with the following issues: --$timestamp${NC}\n"
  printf "$warningmessages\n"
fi

printf "\n${BLUE}[*] Checking for unauthorized users in /etc/passwd...${NC}\n"
usercount=$(wc -l /home/$user/.whiteuser.list | awk '{ print $1 }')
printf "${BLUE}Found $usercount entries...${NC}\n"
sudo grep -oE '^[^:]+' /etc/passwd | fold -s -w15 | sudo tee -a users.lst
unauthusercount=$(wc -l users.lst | awk '{ print $1 }')
authusers=$(sudo cat /home/$user/.whiteuser.list)
userarray=()
for i in $(seq 1 $unauthusercount); do
  unauthusermatch=$(awk '{if(NR=='$i') print $0}' users.lst)
  unauthuserarray+=("$unauthusermatch")
done
authuserarray=()
for i in $(seq 1 $usercount); do
  usermatch=$(awk '{if(NR=='$i') print $0}' /home/$user/.whiteuser.list)
  authuserarray+=("$usermatch")
done
unauthusers=()
for i in "${unauthuserarray[@]}"; do
  skip=   
  for j in "${authuserarray[@]}"; do
    [[ $i == $j ]] && { skip=1; break; }
  done    
  [[ -n $skip ]] || unauthusers+=("$i")
done
unauthuser=$(echo ${unauthusers[@]})
if [ -z "$unauthuser" ]; then
  printf "${BLUE}[+] Users Whitelist Check: ${GREEN}OK --$timestamp${NC}\n"
else
  printf "${RED}[!] Users Whitelist Check: Unapproved users found in /etc/passwd: --$timestamp${NC}\n"
  for i in "${unauthusers[@]}"; do
    printf "$i\n"
  done
fi

printf "${BLUE}[*] Checking if UFW enabled...${NC}\n"
ufwenable=$(sudo ufw status | grep inactive)
if [ -z "$ufwenable" ]; then
  printf "${BLUE}[+] ufw status: ${GREEN}ENABLED --$timestamp${NC}\n"
else
  printf "${RED}[!] ufw status: DISABLED, ENABLING... --$timestamp${NC}\n"
  sudo ufw enable
fi

printf "\n${BLUE}[*] Checking for events from UFW firewall...${NC}\n"
ufwips=$(sudo ufw status | grep -Po "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq -c | awk '{ print $2 }')
echo $ufwips | fold -s -w15| sudo tee -a ufw.ips
ufwipcount=$(sudo ufw status | grep -Po "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq -c | awk '{ print $2 }' | wc | awk '{ print $1 }')
ufwblocked=$(sudo grep "[UFW BLOCK]" /var/log/ufw.log | grep -Po "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq -c | awk '{ print $2 }')
if [ -z "$ufwblocked" ]; then
  printf "${BLUE}[+] ufw.log: ${GREEN}OK --$timestamp${NC}\n"
else
  printf "${RED}[!] ufw.log: Found blocked requests from the following IPs: --$timestamp${NC}\n"
  printf "$ufwblocked\n"
fi

iparray=()
autharray=()
ufwarray=()
for i in $(seq 1 $ipcount); do
  ipmatch=$(awk '{if(NR=='$i') print $0}' /home/$user/.whitehost.list)
  iparray+=("$ipmatch")
done
for i in $(seq 1 $ufwipcount); do
  ufwipmatch=$(awk '{if(NR=='$i') print $0}' ufw.ips)
  ufwarray+=("$ufwipmatch")
done
for i in $(seq 1 $authcount); do
  authipmatch=$(awk '{if(NR=='$i') print $0}' /home/$user/.authips.list)
  autharray+=("$authipmatch")
done
uncheckedips=()
for i in "${iparray[@]}"; do
  skip=   
  for j in "${ufwarray[@]}"; do
    [[ $i == $j ]] && { skip=1; break; }
  done    
  [[ -n $skip ]] || uncheckedips+=("$i")
done
unchecked=$(echo ${uncheckedips[@]})

if [ -z "$unchecked" ]; then
  printf "${BLUE}[+] Ufw Check: ${GREEN}OK--$timestamp${NC}\n"
else
  printf "${RED}[!] Ufw Check: Unapproved IPs not configured into ufw... ${NC}\n"
  for i in "${iparray[@]}"; do
    printf "$i --$timestamp\n"
    sudo ufw allow from $i
  done
fi

printf "\n${BLUE}[*] Checking for unauthorized groups in /etc/group...\n"
groupcount=$(wc -l /home/$user/.whitegroup.list | awk '{ print $1 }')
printf "${BLUE}Found $groupcount entries...${NC}\n"
sudo cat /etc/group | cut -d : -f 1 | fold -s -w15 | sudo tee -a groups.lst
unauthgroupcount=$(wc -l groups.lst | awk '{ print $1 }')
authgroups=$(sudo cat /home/$user/.whitegroup.list)
userarray=()
for i in $(seq 1 $unauthgroupcount); do
  unauthgroupmatch=$(awk '{if(NR=='$i') print $0}' groups.lst)
  unauthgrouparray+=("$unauthgroupmatch")
done
authgrouparray=()
for i in $(seq 1 $groupcount); do
  groupmatch=$(awk '{if(NR=='$i') print $0}' /home/$user/.whitegroup.list)
  authgrouparray+=("$groupmatch")
done
unauthgroups=()
for i in "${unauthgrouparray[@]}"; do
  skip=   
  for j in "${authgrouparray[@]}"; do
    [[ $i == $j ]] && { skip=1; break; }
  done    
  [[ -n $skip ]] || unauthgroups+=("$i")
done
unauthgroup=$(echo ${unauthgroups[@]})
if [ -z "$unauthuser" ]; then
  printf "${BLUE}[+] Groups Whitelist Check: ${GREEN}OK${NC}\n"
else
  printf "${RED}[!] Groups Whitelist Check: Unapproved groups found in /etc/group: ${NC}\n"
  for i in "${unauthgroups[@]}"; do
    printf "$i\n"
  done
fi

unauthips=()
for i in "${autharray[@]}"; do
    skip=
    for j in "${iparray[@]}"; do
        [[ $i == $j ]] && { skip=1; break; }
    done
    [[ -n $skip ]] || unauthips+=("$i")
done
unapproved=$(echo ${unauthips[@]})

printf "\n${BLUE}[*] Checking auth.log\n"
printf "${BLUE}[*] Found $ipcount entries...${NC}\n"

failedlogin=$(sudo grep "Failed password for" /var/log/auth.log | grep -Po "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq -c | awk '{ print $2 }')
if [ -z "$failedlogin" ]; then
  printf "${BLUE}[+] auth.log: ${GREEN}OK--$timestamp${NC}\n"
else
  printf "${RED}[!] Found failed-login attempts from the following IPs: --$timestamp${NC}\n"
  printf "$failedlogin\n"
fi

if [ -z "$unapproved" ]; then
  printf "${BLUE}[+] Auth IPs Whitelist Check: ${GREEN}OK--$timestamp${NC}\n"
else
  printf "${RED}[!] Auth IPs Whitelist Check: Unapproved IPs found in auth.log: ${NC}\n"
  for i in "${unauthips[@]}"; do
    printf "$i  --$timestamp\n"
  done
fi

sudo rm ufw.ips
sudo rm groups.lst
sudo rm users.lst
