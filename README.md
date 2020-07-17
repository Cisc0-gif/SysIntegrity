# SysIntegrity - File and Log Integrity Check

SysIntegrity allows users to add files on their system to a registry which would then be checked on startup. If a file has an unwarranted change, the hash would be changed which would trigger a red flag and warn the user of possible intrusion.

UPDATE: **Now supporting auth.log IP whitelisting, ufw.log parsing for [UFW BLOCK] messages, ufw IP passthrough, and rkhunter.log.1 parsing for warning messages!**

COMING SOON: **Just uploaded new group and user whitelist check for main.sh, will clean up and add to cronjob in a few days**

## Getting Started

To setup, add files to the whitelist, and create a cronjob, run ``` ./main.sh ``` 

If you make a change to a file on the whitelist you're going to have to add the file again and remove the old entry from the whitelist. This tool is meant for critical system files that require little to no reoccuring configuration.

## Built With

* Ubuntu - Debian Linux OS
* Kali Linux - Pentesting OS developed by Offensive Security
* GitHub - This Website!

## Authors

* **Cisc0-gif** - *Main Contributor/Author*: Ecorp7@protonmail.com

## License

This project is licensed under the GNU General Public License v3 - see the LICENSE file for details


## Acknowledgments

All credits are given to the authors and contributors to tools used in this software
